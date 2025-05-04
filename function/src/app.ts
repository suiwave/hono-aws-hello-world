import { Hono } from 'hono'

const app = new Hono()

app.
    get('/', (c) => {
        return c.text('Hello Hono!')
    })
    .get('/posts', (c) => {
        return c.text('GET /posts !!')
    })
    .post('/users', (c) => {
        return c.text('POST /users !!')
    })

export default app