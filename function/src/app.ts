import { Hono } from 'hono'

import book from './routes/book'
import user from './routes/user'

const app = new Hono()

app.route('/book', book)
app.route('/user', user)

export default app