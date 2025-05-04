import { Hono } from 'hono'

const user = new Hono()

user.get('/', (c) => c.text('List Users')) // GET /user
user.get('/:id', (c) => {
    // GET /user/:id
    const id = c.req.param('id')
    return c.text('Get User: ' + id)
})
user.post('/', (c) => c.text('Create User')) // POST /user

export default user