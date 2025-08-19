//SystemVerilog
module decoder_delay_comp #(parameter STAGES=3) (
    input clk,
    input [4:0] addr,
    output reg [31:0] decoded
);
    reg [31:0] decoded_pipe [0:STAGES-2];
    integer i;
    
    always @(posedge clk) begin
        // First stage - compute decoded value directly from input
        decoded_pipe[0] <= 1'b1 << addr;
        
        // Middle stages - pipeline the decoded value
        for(i=1; i<STAGES-1; i=i+1)
            decoded_pipe[i] <= decoded_pipe[i-1];
            
        // Final stage - output register
        if (STAGES > 1) begin
            decoded <= decoded_pipe[STAGES-2];
        end
        else begin
            decoded <= decoded_pipe[0];
        end
    end
endmodule