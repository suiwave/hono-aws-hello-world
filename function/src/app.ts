import { Hono } from 'hono'

const app = new Hono()

app.
    get('/', (c) => {
        return c.text('Hello Hono!')
    })
    .get('/post', (c) => {
        return c.text('post!')
    })

export default app