//SystemVerilog
module MuxBinaryEnc #(parameter W=8, N=16) (
    input [N-1:0] req,
    input [W-1:0] data [0:N-1],
    output reg [W-1:0] grant_data
);

    wire [N-1:0] req_priority;
    wire [W-1:0] mux_data [0:N-1];
    
    // Priority encoder
    assign req_priority[0] = req[0];
    genvar i;
    generate
        for(i=1; i<N; i=i+1) begin : gen_priority
            assign req_priority[i] = req[i] & ~(|req[i-1:0]);
        end
    endgenerate
    
    // Data multiplexing
    genvar j;
    generate
        for(j=0; j<N; j=j+1) begin : gen_mux
            assign mux_data[j] = req_priority[j] ? data[j] : {W{1'b0}};
        end
    endgenerate
    
    // Final OR reduction
    always @(*) begin
        grant_data = {W{1'b0}};
        for(int k=0; k<N; k=k+1) begin
            grant_data = grant_data | mux_data[k];
        end
    end

endmodule