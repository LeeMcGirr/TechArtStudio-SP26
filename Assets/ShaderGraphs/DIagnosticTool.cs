using UnityEngine;

[ExecuteInEditMode]
public class DiagnosticTool : MonoBehaviour
{


    MeshRenderer myMeshRend;
    // Start is called once before the first execution of Update after the MonoBehaviour is created

    void OnEnable()
    {
        myMeshRend = GetComponent<MeshRenderer>();
        Debug.Log("meshRend min: " + myMeshRend.bounds.min + " and max: " + myMeshRend.bounds.max + " and dist: " + myMeshRend.bounds.size);
    }
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
