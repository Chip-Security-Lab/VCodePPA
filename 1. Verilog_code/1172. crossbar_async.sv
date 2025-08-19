module crossbar_async #(parameter WIDTH=16, INPUTS=3, OUTPUTS=3) (
    input [(WIDTH*INPUTS)-1:0] in_data,
    input [(OUTPUTS*INPUTS)-1:0] req,
    output [(WIDTH*OUTPUTS)-1:0] out_data
);

genvar o, i;
generate 
    for(o=0; o<OUTPUTS; o=o+1) begin : gen_out
        wire [INPUTS-1:0] req_vec;
        wire any_req;
        reg [WIDTH-1:0] out_temp;
        
        // Extract request bits for this output
        for(i=0; i<INPUTS; i=i+1) begin : gen_req
            assign req_vec[i] = req[i*OUTPUTS + o];
        end
        
        assign any_req = |req_vec;
        
        // Priority encoder implementation using case instead of dynamic loop
        always @(*) begin
            out_temp = {WIDTH{1'b0}};
            casez(req_vec)
                3'b??1: out_temp = in_data[WIDTH-1:0];
                3'b?10: out_temp = in_data[2*WIDTH-1:WIDTH];
                3'b100: out_temp = in_data[3*WIDTH-1:2*WIDTH];
                default: out_temp = {WIDTH{1'b0}};
            endcase
        end
        
        assign out_data[(o+1)*WIDTH-1:o*WIDTH] = any_req ? out_temp : {WIDTH{1'b0}};
    end
endgenerate
endmodule