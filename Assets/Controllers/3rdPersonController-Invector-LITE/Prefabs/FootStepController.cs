using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FootStepController : MonoBehaviour
{
    public ParticleSystem leftFoot, rightFoot;
    Rigidbody rb;
    void FootStepEvent(int foot) 
    {
        if (rb.linearVelocity.magnitude > 0.1f)
        {
            Debug.Log("footStepped: " + foot);
            if (foot == 1)
            {
                leftFoot.Play();
            }
            else if (foot == 0) { rightFoot.Play(); }
        }
    }
    // Start is called before the first frame update
    void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

}
