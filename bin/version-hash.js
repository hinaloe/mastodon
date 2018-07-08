#!/bin/env node

const fs = require('fs')

if(process.argv[2]==null) {
	console.error('This patch require first argment: commit hash')
	process.exit(1)
}

fs.readFile('lib/mastodon/version.rb', 'utf8', (err, data) => {
	if(err) {
		console.error(err)
		process.exit(1)
	}
	
	const newData = data.replace(/(?<=def flags\s+')([^']*)(?='\s+end)/g, `$1-${process.argv[2]}`)

	fs.writeFile('lib/mastodon/version.rb', newData, 'utf8', (err)=>{
		if(err) {
			console.error(err)
			process.exit(1)
		}
		console.log('version patched')
	})
})
