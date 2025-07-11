TOPTARGETS := all clean update

$(TOPTARGETS): pre_build make_fastPathSign make_roothelper make_trollstore make_trollhelper_embedded make_trollhelper_package assemble_trollstore build_installer15 build_installer64e make_trollstore_lite

pre_build:
	rm -rf ./_build 2>/dev/null || true
	mkdir -p ./_build
	echo "[INFO] Created _build directory."

make_fastPathSign:
	echo "[INFO] Building fastPathSign..."
	$(MAKE) -C ./Exploits/fastPathSign $(MAKECMDGOALS)

make_roothelper:
	echo "[INFO] Building RootHelper..."
	$(MAKE) -C ./RootHelper DEBUG=0 $(MAKECMDGOALS)

make_trollstore:
	echo "[INFO] Building TrollStore..."
	$(MAKE) -C ./TrollStore FINALPACKAGE=1 $(MAKECMDGOALS)

ifneq ($(MAKECMDGOALS),clean)

make_trollhelper_package:
	echo "[INFO] Building TrollHelper (packaged)..."
	$(MAKE) clean -C ./TrollHelper
	cp ./RootHelper/.theos/obj/trollstorehelper ./TrollHelper/Resources/trollstorehelper
	$(MAKE) -C ./TrollHelper FINALPACKAGE=1 package $(MAKECMDGOALS)
	$(MAKE) clean -C ./TrollHelper
	$(MAKE) -C ./TrollHelper THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1 package $(MAKECMDGOALS)
	rm ./TrollHelper/Resources/trollstorehelper

make_trollhelper_embedded:
	echo "[INFO] Building TrollHelper (embedded)..."
	$(MAKE) clean -C ./TrollHelper
	$(MAKE) -C ./TrollHelper FINALPACKAGE=1 EMBEDDED_ROOT_HELPER=1 $(MAKECMDGOALS)
	cp ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/TrollStorePersistenceHelper ./_build/PersistenceHelper_Embedded
	$(MAKE) clean -C ./TrollHelper
	$(MAKE) -C ./TrollHelper FINALPACKAGE=1 EMBEDDED_ROOT_HELPER=1 LEGACY_CT_BUG=1 $(MAKECMDGOALS)
	cp ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/TrollStorePersistenceHelper ./_build/PersistenceHelper_Embedded_Legacy_arm64
	$(MAKE) clean -C ./TrollHelper
	$(MAKE) -C ./TrollHelper FINALPACKAGE=1 EMBEDDED_ROOT_HELPER=1 CUSTOM_ARCHS=arm64e $(MAKECMDGOALS)
	cp ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/TrollStorePersistenceHelper ./_build/PersistenceHelper_Embedded_Legacy_arm64e
	$(MAKE) clean -C ./TrollHelper

assemble_trollstore:
	echo "[INFO] Assembling TrollStore.tar..."
	cp ./RootHelper/.theos/obj/trollstorehelper ./TrollStore/.theos/obj/TrollStore.app/trollstorehelper
	cp ./TrollHelper/.theos/obj/TrollStorePersistenceHelper.app/TrollStorePersistenceHelper ./TrollStore/.theos/obj/TrollStore.app/PersistenceHelper
	export COPYFILE_DISABLE=1
	tar -czvf ./_build/TrollStore.tar -C ./TrollStore/.theos/obj TrollStore.app

build_installer15:
	echo "[INFO] Building iOS 15 installer IPA..."
	mkdir -p ./_build/tmp15
	unzip ./Victim/InstallerVictim.ipa -d ./_build/tmp15
	cp ./_build/PersistenceHelper_Embedded_Legacy_arm64 ./_build/TrollStorePersistenceHelperToInject
	pwnify set-cpusubtype ./_build/TrollStorePersistenceHelperToInject 1
	ldid -s -K./Victim/victim.p12 ./_build/TrollStorePersistenceHelperToInject
	APP_PATH=$$(find ./_build/tmp15/Payload -name "*" -depth 1) ; \
	APP_NAME=$$(basename $$APP_PATH) ; \
	BINARY_NAME=$$(echo "$$APP_NAME" | cut -f 1 -d '.') ; \
	echo "[INFO] Patching binary: $$BINARY_NAME" ; \
	pwnify pwn ./_build/tmp15/Payload/$$APP_NAME/$$BINARY_NAME ./_build/TrollStorePersistenceHelperToInject
	pushd ./_build/tmp15 ; \
	zip -vrD ../../_build/TrollHelper_iOS15.ipa * ; \
	popd
	rm ./_build/TrollStorePersistenceHelperToInject
	rm -rf ./_build/tmp15

build_installer64e:
	echo "[INFO] Building arm64e installer IPA..."
	mkdir -p ./_build/tmp64e
	unzip ./Victim/InstallerVictim.ipa -d ./_build/tmp64e
	APP_PATH=$$(find ./_build/tmp64e/Payload -name "*" -depth 1) ; \
	APP_NAME=$$(basename $$APP_PATH) ; \
	BINARY_NAME=$$(echo "$$APP_NAME" | cut -f 1 -d '.') ; \
	echo "[INFO] Patching binary: $$BINARY_NAME" ; \
	pwnify pwn64e ./_build/tmp64e/Payload/$$APP_NAME/$$BINARY_NAME ./_build/PersistenceHelper_Embedded_Legacy_arm64e
	pushd ./_build/tmp64e ; \
	zip -vrD ../../_build/TrollHelper_arm64e.ipa * ; \
	popd
	rm -rf ./_build/tmp64e

make_trollstore_lite:
	echo "[INFO] Building TrollStore Lite..."
	$(MAKE) -C ./RootHelper DEBUG=0 TROLLSTORE_LITE=1
	rm -rf ./TrollStoreLite/Resources/trollstorehelper
	cp ./RootHelper/.theos/obj/trollstorehelper_lite ./TrollStoreLite/Resources/trollstorehelper
	$(MAKE) -C ./TrollStoreLite package FINALPACKAGE=1
	$(MAKE) -C ./RootHelper TROLLSTORE_LITE=1 clean
	$(MAKE) -C ./TrollStoreLite clean
	$(MAKE) -C ./RootHelper DEBUG=0 TROLLSTORE_LITE=1 THEOS_PACKAGE_SCHEME=rootless
	rm -rf ./TrollStoreLite/Resources/trollstorehelper
	cp ./RootHelper/.theos/obj/trollstorehelper_lite ./TrollStoreLite/Resources/trollstorehelper
	$(MAKE) -C ./TrollStoreLite package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless

else
make_trollstore_lite:
	$(MAKE) -C ./TrollStoreLite $(MAKECMDGOALS)
endif

.PHONY: $(TOPTARGETS) pre_build assemble_trollstore make_trollhelper_package make_trollhelper_embedded build_installer15 build_installer64e
