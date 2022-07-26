import Pkg.PlatformEngines.download_verify, CodecBzip2.Bzip2DecompressorStream, VGDatasets.localpath
export loadbaldataset, readbalfile

struct BALDataset{T<:AbstractFloat}
    measurementindices::Matrix{Int}
    measurements::Matrix{T}
    cameras::Matrix{T}
    landmarks::Matrix{T}
end 

function readbalfile(fpath::String, T::Type=Float64)
open(fpath, "r") do fh
    stream = Bzip2DecompressorStream(fh)

    # Get the numbers of things
    numcameras, numlandmarks, nummeasurements = parse.(Int, split(readline(stream)))

    # Read in the measurements
    measurementindices = Matrix{Int}(undef, 2, nummeasurements)
    measurements = Matrix{T}(undef, 2, nummeasurements)
    for ind = 1:nummeasurements
        camera, landmark, x, y = split(readline(stream))
        measurementindices[:,ind] = [parse(Int, camera) parse(Int, landmark)] .+ 1
        measurements[:,ind] = [parse(T, x) parse(T, y)]
    end

    # Read in the remaining data
    variables = [parse(T, line) for line in eachline(stream)]

    # Return the dataset
    return BALDataset(measurementindices,
                      measurements, 
                      reshape(variables[1:numcameras*9], 9, numcameras),
                      reshape(variables[numcameras*9+1:end], 3, numlandmarks))
end
end

function loadbaldataset(name::String, T::Type=Float64)
# Find the entry that matches the name
groupname, fname, sha256 = getinfo(name)

# Get the cache folder
dname = joinpath(localpath(), "BAL")
mkpath(dname)

# Check the file is dowloaded
fpath = joinpath(dname, string(groupname, '-', fname))
url = joinpath("https://grail.cs.washington.edu/projects/bal/data/", groupname, fname)
download_verify(url, sha256, fpath)

# Read the file
return readbalfile(fpath, T)
end

const dubrovnik = [
  "problem-16-22106" "0d695947deb3fc3026e5434a904151b18fe8e60c0176e430dcb5e7a3da039ca5";
  "problem-88-64298" "0932671dd91eb8a36a24ad3c13495e7131e198cdcc30b0c606ab44458a72846b";
  "problem-135-90642" "010434b003c5355d1184887e32d504f2a8c558cb8454ced8d918b8b2c1dfd8df";
  "problem-142-93602" "4d06f15adf3a08933008a0ceb977e85af2d8ba9a16c268b9c2a8a736376fb990";
  "problem-150-95821" "6b5029fe412def51f503b28901b57934ad856b51c10fc71e52a6e889c1fa628d";
  "problem-161-103832" "060b21cdd51434c1a515d13238eb03acbc8706f2821f3d43e92989a5719aedbc";
  "problem-173-111908" "116eda2831e5b27716027c35e3aebb3de2830850189a2775fad4f4cdff6be298";
  "problem-182-116770" "e7a170df761b28b484ac6f0c1e9c07187a212943d7ab378887432e74a4e08e17";
  "problem-202-132796" "4e2f8f74718021b39e8249f04e7bcb695267b8a353f2a49175e2df94f9267a36";
  "problem-237-154414" "817f324be685d2a61bfdc33cc99e67ca1de2941be8dce013040b38795199a2cf";
  "problem-253-163691" "9cb658e3149c9eed4f5d99181a13477029a71e9e8400364d0c83f286835d709c";
  "problem-262-169354" "84b0c8061a744ade39e8c2753bc26141686e3362a274d0a0826ab38a9bbd5bf9";
  "problem-273-176305" "5b355eb9680d820c1d85a0eb4bed655814de3c5dab7d3fd14dd0044fc0d7887e";
  "problem-287-182023" "2974f60f632551deb9e51fd53284571bc5abf52b5df8d715d327a505653856b9";
  "problem-308-195089" "409a1a17a86dd486212a4ba270038eabe62a98399dff6d9c0cd6c6c703b79e1d";
  "problem-356-226730" "d6e2e04864c88f1af2c12e91af4ee8cddab6e2a72d6b1bd5fa3c8883c971e365";
]

const trafalgar = [
  "problem-21-11315" "4a4ed35e334af9a60661bf83f1e86842e772f22a967113932456c5ebcf40e5e6";
  "problem-39-18060" "878b3aa55d85f1ed97d5e46ce89a26feed869cb7b951e3e6cd4703508e630bde";
  "problem-50-20431" "93612e50a76ca65ce84ee725590909fcd9ab01b88c0ab1f9b5215d4dc6d35e78";
  "problem-126-40037" "74f191aa27721e43d4d79f02906f225604efa19fedce42d2dfe111d39144978b";
  "problem-138-44033" "623bd65f9e741534829120abca4a8d39422281c2b1d16258322a7a79e6ea7764";
  "problem-161-48126" "516d34d6a24c14e56eff7ce7902f2adb8d0367d1a8714a2f7975e03d48afa32e";
  "problem-170-49267" "5ec749cbd48e23bc89e1023858222fed0f97ebd839b35681a3d7164ce050bca8";
  "problem-174-50489" "5eda296cb9aa81b1b5692c0ce5df9ee3cef142ce869f45b2d20225f521503757";
  "problem-193-53101" "6585085298a24c761360805e203c18f0b24943928f7734bf363f351fe700e3f2";
  "problem-201-54427" "7635be4cd27770be9dfff5b4cf40db405cd29880c49c28711f1be248d55adbe4";
  "problem-206-54562" "86718117c6bbbc85039430f116965e3bf647f057fd3a5508ecc8c3f9614ba150";
  "problem-215-55910" "610e3cc1c955d862b570b4578dfa11cf009b6e0bb8c22a34121727db74111223";
  "problem-225-57665" "465663708cbd1f1c1e8face9ac26e187ca8c0e1366eb9cb0657e87b444af3d1e";
  "problem-257-65132" "c265ccb6dcb668f7e6248b4359f9c3f1e9fd82087d768f30331474c4c5a55d21";
]

const ladybug = [
  "problem-49-7776" "1ccb15701a92a8ad909d30860a0108cd3f2d7916c1ecf2851e59a6198b9de6b0";
  "problem-73-11032" "136d1b3814309cd1909dc5ab598fb5dcf83988ee47568c97a05804135721756c";
  "problem-138-19878" "0b7016e233ed8e0a4aa7dec79cca3d7dd6ffc40fd01846e1d0c9d2de1247a2b2";
  "problem-318-41628" "228ee2613466e25e81821ca424044065c030913a5e5eb2feeac2246f0890ef63";
  "problem-372-47423" "071258cbfe6a882dc83204660682bbe9a8118f6ee2cc43c16813bf6fca75cdc2";
  "problem-412-52215" "cdab718d5a98738f6aa305b646645863ddc46360ef5fa128b2431d7f4777ee35";
  "problem-460-56811" "962e8b3980526100c383f5970e47f07a316024172148d62c42dcb925b60c1065";
  "problem-539-65220" "45064e69fa3bbe37badf0c7af1ae5f64b19e0e716b0e873c2ef67ca6bb1297a1";
  "problem-598-69218" "33f5129f8de00458fb539608960b4e5f8244020aa3163f2e9dc60973c07c4110";
  "problem-646-73584" "990233f390fc2de3ac1e637e84940cb0de86baaccdd732a2ae309d2527d28936";
  "problem-707-78455" "5614d1e477bc7d0e954efe5e84cb84b81870cac4dca04efd0b21d0e5dc3d7f4f";
  "problem-783-84444" "93b24d5d5564a9d913e6bf826457026597cc7b121215e40cdd0715009b755145";
  "problem-810-88814" "2200bdafd380a32c4037e41c20bcfc7400018553d18193818617670117e10f17";
  "problem-856-93344" "a455ef5c248c23dfd6596a2ae26c456224cc03e921a178c741eb4859610bced2";
  "problem-885-97473" "c2ede5ef5604a91a1627c016191cdfd00beed6e45ae6ec5131fea98155f5b378";
  "problem-931-102699" "7ed3916fbcf2ecef936415da48317142fc35fa3a351b7eab64cd386fe2f285db";
  "problem-969-105826" "717e82344b5dd9251e6e33adafb2fe5be372db7c4e19540a9676b02fb2b252b1";
  "problem-1031-110968" "3a3fbed7026284aa7b670d223807870c24aacd4946ccc60bf8abbe86de79e116";
  "problem-1064-113655" "618dd7a3af97b49b20976f502deff19eed9f64a0730989b49798ee69082fd24b";
  "problem-1118-118384" "e05f866597c5ab837cda7d3221f9fa27d67ef20607d1ebf9696a2b311bd8b6a0";
  "problem-1152-122269" "dcb9a1e70e2c28575403974fd85e8a4fc3e0388535a9b791a13639b575fb3623";
  "problem-1197-126327" "2453195a61a56311b79c22c483960905dc131ee4172f294187173fea224d5736";
  "problem-1235-129634" "10b8515082dc065266e7d0ddad2d070dcb55529fbc20ff78679d2b99f08bcb3b";
  "problem-1266-132593" "5c6bfa1cf103bfffad578ce746c4dc306df0359696748d5b94cfe46c16d36183";
  "problem-1340-137079" "9521c5e29b96492a2ab84c777e4ed10b95655a88639fdb3716e8c546c1156f9c";
  "problem-1469-145199" "11d4d93fd5d7d6575f2f2b38a46955d4692e10921ac10fadb92506030c21e567";
  "problem-1514-147317" "1b08f5a1a112f697a9f3480a6887db77b0095540b2c9c613d90ea40b9dcfd86d";
  "problem-1587-150845" "ca6a310fcd3c5649fd4b17a7f13356fc7a6f8033e3932e82f42432eb90d0f948";
  "problem-1642-153820" "5e44fcf7e79862d53343cdaf80ee177c4b59d7193d1022f1b5934c28d34e9348";
  "problem-1695-155710" "c4f52c978513a0bccde40f5e607d5570e16608932ae4f2817ec7e82c0dd074ab";
]

const venice = [
  "problem-52-64053" "f378c9774e92f02b6b97f1e790458ebefb444ea26def60580a7e38224c43a753";
  "problem-89-110973" "a565e3160c1334184eec8e135d2373c7e9f0fa7754cc6000a43aef12eac811e6";
  "problem-245-198739" "4a6e53efc2fd8d4b9901003627aba3dcae83470a1692424f711fd7f6fa7a0308";
  "problem-427-310384" "a6aa017a5755c8ddea1bf67d9f73789cd3d83b198c655d0b06c1fe2c6c91c0e0";
  "problem-744-543562" "e1576e5fa00d8770b1ec9b86b44841c20d997f8903e89158dcb2ee1f446cdb04";
  "problem-951-708276" "1afb64d65cb376795db8c7e6a7427922621d462718e447ec8012b4bda9b1d29a";
  "problem-1102-780462" "125a36eecb94ecfa3081b9bd462c5eb6a9df59356f3e3d632fe735770dcd75d1";
  "problem-1158-802917" "f13f98178e7dd281553603be6afb26fad5ebfb26f15ac8db6cb8e0bbd76b6146";
  "problem-1184-816583" "256d8a47a4c8983414ac2783580d6c2f1a076fdd01f3f13d5e76ec63298f5b9a";
  "problem-1238-843534" "eae300a89ba8d87664af3c03ff29c9581e289230a8643f5cb0e90c661683584f";
  "problem-1288-866452" "513530dc1b23164e60a10692721db9ea83a44c45ec5dd22fdcdc58f9c0c4e2c2";
  "problem-1350-894716" "c0057bbff603719b2baacbf103dacb5c0415bd0e72464ea3ea927eae3b06f802";
  "problem-1408-912229" "022349f22648d6948d664e93c1e47dd3afa6352c67357304533b530a82fbdca1";
  "problem-1778-993923" "5a47b1f594e3e66f0ee56c66cd5d07fd15531861b9856bf2ab604b079dc3c914";
]

const final = [
  "problem-93-61203" "6ac514d3dde4e23ca7751b50799188d808188848e1e88c72fc9e67df2701896f";
  "problem-394-100368" "565fa96016bf373688f33dfd33af37f4d867dae5736796c6342ab748c746033c";
  "problem-871-527480" "8afde9a4421d7d3cdc73a062f1f2ae80c30c71ca06b15220991bc90da974cbd5";
  "problem-961-187103" "170da6f17719d6e3cf85da356b09467920ac3e1187c104d5be510a8272f57de5";
  "problem-1936-649673" "89e44afc13d7db557e33995c086b1eb192f26eccbdf34e488df0eac8cb166057";
  "problem-3068-310854" "a062641dd40ff96e8572d1c6e3372c28c4ab8ac04c5dc61585d8645ee654104a";
  "problem-4585-1324582" "34d8680a255bfbd79ba2058756dcc799ecce80371c4cb8625ed187b2efadc8b8";
  "problem-13682-4456117" "16879a11695cfbc8aadadeb99d85128b8085aaa4e9e3b0b021c9dba67a0ea6cd"
]

const balgroups = Dict("dubrovnik"=>dubrovnik, "trafalgar"=>trafalgar, "ladybug"=>ladybug, "venice"=>venice, "final"=>final)

function getinfo(name::String)
for group = keys(balgroups)
    for row = eachrow(balgroups[group])
        if name == row[1]
            return (group, string(row[1], "-pre.txt.bz2"), row[2])
        end
    end
end
throw(DomainError(string("Dataset name ", name, " not recognised")))
end
