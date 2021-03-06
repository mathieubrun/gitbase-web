package service

import (
	"context"
	"database/sql"
)

// SQLDB describes a *sql.DB
type SQLDB interface {
	Close() error
	Conn(context.Context) (*sql.Conn, error)
	Query(query string, args ...interface{}) (*sql.Rows, error)
	QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error)
	QueryRow(query string, args ...interface{}) *sql.Row
	Ping() error
	Exec(query string, args ...interface{}) (sql.Result, error)
}
