import tensorflow as tf


def test_hello_tf():
    hello = tf.constant('Hello, TensorFlow!')
    sess = tf.Session()
    assert sess.run(hello).decode('utf-8') == 'Hello, TensorFlow!'
