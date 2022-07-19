#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include "fvCFD.H"
#include "argList.H"
#include "primitivePatchInterpolation.H"
#include "timeSelector.H"
#include "twoPhaseMixture.H"


using namespace Foam;


#include "timeDataList.H"


int main(int argc, char *argv[])
{
	#   include "setRootCase.H"
	#   include "createTime.H"
	#   include "createNamedMesh.H"

	IOdictionary postProcessDict 
	(
		IOobject
		(
			"postProcessDict",
			"system",
			mesh,
			IOobject::MUST_READ,
			IOobject::NO_WRITE
		)
	);
	label nSatPoints
	(
		readScalar(postProcessDict.lookup("nSatPoints"))
	);

	label offset
	(
		readScalar(postProcessDict.lookup("offset"))
	);

                scalar z1
                (
                    readScalar(postProcessDict.lookup("z1"))
                );


                scalar z2
                (
                    readScalar(postProcessDict.lookup("z2"))
                );

                scalar y1
                (
                    readScalar(postProcessDict.lookup("y1"))
                );


                scalar y2
                (
                    readScalar(postProcessDict.lookup("y2"))
                );


                scalar x1
                (
                    readScalar(postProcessDict.lookup("x1"))
                );


                scalar x2
                (
                   readScalar(postProcessDict.lookup("x2"))
                );

                label direction
                (
                    readLabel(postProcessDict.lookup("direction"))
                );


	IOdictionary transportProperties 
	(
		IOobject
		(
			"transportProperties",
			"constant",
			mesh,
			IOobject::MUST_READ,
			IOobject::NO_WRITE
		)
	);

    word phase1Name(transportProperties.lookupOrDefault<word>("phase1","phase1"));
    word phase2Name(transportProperties.lookupOrDefault<word>("phase2","phase2"));

    dimensionedScalar rho1
    (
        transportProperties.subDict(phase1Name).lookup("rho")
    );

    dimensionedScalar rho2
    (
        transportProperties.subDict(phase2Name).lookup("rho")
    );

    dimensionedScalar nu1
    (
        transportProperties.subDict(phase1Name).lookup("nu")
    );

    dimensionedScalar nu2
    (
        transportProperties.subDict(phase2Name).lookup("nu")
    );

    dimensionedScalar mu1 = rho1*nu1;

    dimensionedScalar mu2 = rho2*nu2;

	dimensionedScalar sigma
	(
		transportProperties.lookup("sigma")
	);

	instantList timeList = timeSelector::select0(runTime, args);
	timeDataList dataList(timeList.size());


	forAll(timeList, timeStep)
	{	
		runTime.setTime(timeList[timeStep], timeStep);

		Info<< endl<<timeStep<< "    Time = " << runTime.timeName() << endl;

		timeData& data=dataList.data[timeStep];

		volScalarField alpha1 
		(
			IOobject
			(
				"alpha1",
				runTime.timeName(),
				mesh,
				IOobject::MUST_READ,
				IOobject::NO_WRITE
			),
			mesh
		);

                volScalarField pc 
                (
                        IOobject
                        (
                                "pc",
                                runTime.timeName(),
                                mesh,
                                IOobject::MUST_READ,
                                IOobject::NO_WRITE
                        ),
                        mesh
                );



		volVectorField U
		(
			IOobject
			(
				"U",
				runTime.timeName(),
				mesh,
				IOobject::MUST_READ,
				IOobject::NO_WRITE
			),
			mesh
		);

	 	#include "createPhi.H"

		twoPhaseMixture twoPhaseProperties(U, phi);

		surfaceScalarField muEff
		(
			"muEff",
			twoPhaseProperties.muf()
		);

		volScalarField UD=U.component(direction);
		volScalarField viscPRate=(fvc::laplacian(muEff,U) & U);


		volScalarField clip
		(
			IOobject
			(
				"clip",
				runTime.timeName(),
				mesh,
				IOobject::NO_READ,
				IOobject::AUTO_WRITE
			),
			mesh,
			dimensionedScalar("clip",dimVolume,0.0)
		);	

                volScalarField coordz=mesh.C().component(2);
                volScalarField coordy=mesh.C().component(1);
                volScalarField coordx=mesh.C().component(0);

                forAll(mesh.cells(),j)
                {
                    scalar zj=coordz[j];
                    scalar yj=coordy[j];
                    scalar xj=coordx[j];
                    if (zj>=z1 && zj<=z2 && yj>=y1 && yj<=y2 && xj>=x1 && xj<=x2)
                    {
                            clip[j]=mesh.V()[j];
                    }
                }


		scalar alpha = (sum(alpha1*clip)/sum(clip)).value();
		scalar UAvg=(sum(UD*clip)/sum(clip)).value();
		scalar vol=sum(clip).value();
		scalar U1 =(sum(UD*alpha1*clip)/sum(clip)).value();
		scalar U2 = UAvg-U1;
		scalar viscP=(sum(viscPRate*clip)/sum(clip)).value();
		scalar viscP_1=(sum(viscPRate*alpha1*clip)/sum(clip)).value();
		scalar Ca_1 = UAvg*mu1.value()/sigma.value();
		scalar Ca_2 = UAvg*mu2.value()/sigma.value();
                scalar p1 = (sum(pc*alpha1*clip)/sum(clip)).value();
                scalar p2 = (sum(pc*(1-alpha1)*clip)/sum(clip)).value();

		data.t=runTime.value();
		data.alpha=alpha;
		data.U1=U1;
		data.U2=U2;
		data.vol=vol;
		data.viscP=viscP;
		data.viscP_1=viscP_1;
		data.Ca_1 = Ca_1;
		data.Ca_2 = Ca_2; 
                data.p1 = p1;
                data.p2 = p2;
	}

	if (Pstream::master())
	{
		timeDataList AverageDataList(dataList,nSatPoints,offset);

		//Read single phase dictionary
		IOdictionary SPDict 
		(
			IOobject
			(
				"SPDict",
				"system",
				mesh,
				IOobject::MUST_READ,
				IOobject::NO_WRITE
			)
		);
		
		scalar poro
		(
			readScalar(SPDict.lookup("poro"))
		);

		scalar perm
		(
			readScalar(SPDict.lookup("perm"))
		);

		scalar Ca_1 = 0.0;
		scalar Ca_2 = 0.0;


		for (int i=0;i<nSatPoints-1;i++)
		{
			Ca_1 = std::max(Ca_1,AverageDataList.data[i].Ca_1);
			Ca_2 = std::max(Ca_2,AverageDataList.data[i].Ca_2);
		}


		std::ofstream csvfile("relperm.csv");
		csvfile << "poro " << poro << " \n";
		csvfile << "perm " << perm << " m2\n";
		csvfile << "Ca1 " << Ca_1 << " Ca2 " << Ca_2 << "\n";
		csvfile << "Sw krw kwo \n";

		//write properties excel file
		for (int i=0;i<nSatPoints;i++)
		{
			scalar alpha   = AverageDataList.data[i].alpha;
			scalar U1      = AverageDataList.data[i].U1;
			scalar U2      = AverageDataList.data[i].U2;
			scalar vol     = AverageDataList.data[i].vol;
			scalar viscP   = AverageDataList.data[i].viscP;
			scalar viscP_1 = AverageDataList.data[i].viscP_1;

			scalar viscP_2 = viscP - viscP_1;

			scalar Q1 = U1*vol+1e-32;
			scalar Q2 = U2*vol+1e-32;

			scalar dP1dz = viscP_1*vol/Q1+1e-32;
			scalar dP2dz = viscP_2*vol/Q2+1e-32;


			scalar krw=-mu1.value()*(U1*poro/dP1dz)/perm;
			scalar kro=-mu2.value()*(U2*poro/dP2dz)/perm;

			csvfile << alpha << " " << krw << " " << kro << " " << "\n";
		}
		csvfile.close();
	}

	return 0;
}


// ************************************************************************* //
