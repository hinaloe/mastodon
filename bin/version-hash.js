#!/bin/env node

const fs = require('fs')
const {resolve} = require('path')

if(process.argv[2]==null) {
	console.error('This patch require first argment: commit hash')
	process.exit(1)
}

const versionFile = resolve(__dirname, '../lib/mastodon/version.rb')
console.log(`Patch applying for ${versionFile}`)
fs.readFile(versionFile, 'utf8', (err, data) => {
	if(err) {
		console.error(err)
		process.exit(1)
	}
	
	const newData = data.replace(/(def flags\s+')([^']*)('\s+end)/g, `$1$2-${process.argv[2]}$3`)

	fs.writeFile(versionFile, newData, 'utf8', (err)=>{
		if(err) {
			console.error(err)
			process.exit(1)
		}
		console.log('version patched')
	})
})
