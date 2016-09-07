clean:
	rm *~
	cp previous_state.txt tmp.tmp
	rm *.txt
	mv tmp.tmp previous_state.txt
