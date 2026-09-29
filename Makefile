.PHONY: app run icon package clean

app:
	Scripts/build.sh

run: app
	-pkill -x Melatonin
	open build/Melatonin.app

icon:
	Scripts/make-icon.sh

package:
	Scripts/package.sh

clean:
	rm -rf .build build dist
