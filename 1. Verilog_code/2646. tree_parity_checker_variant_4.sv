//SystemVerilog
module tree_parity_checker (
    input clk,
    input rst_n,
    input req,           // Request signal (replacing valid)
    input [31:0] data,   // Data input
    output reg ack,      // Acknowledge signal (replacing ready)
    output reg parity    // Parity output
);

    // Internal signals for parity calculation
    wire [15:0] stage1;
    wire [7:0]  stage2;
    wire [3:0]  stage3;
    wire [1:0]  stage4;
    wire        parity_result;
    
    // Parity calculation logic
    assign stage1 = data[31:16] ^ data[15:0];
    assign stage2 = stage1[15:8] ^ stage1[7:0];
    assign stage3 = stage2[7:4] ^ stage2[3:0];
    assign stage4 = stage3[3:2] ^ stage3[1:0];
    assign parity_result = stage4[1] ^ stage4[0];
    
    // Request-Acknowledge handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
            parity <= 1'b0;
        end else begin
            if (req && !ack) begin
                // When request comes and not yet acknowledged
                parity <= parity_result;
                ack <= 1'b1;
            end else if (!req && ack) begin
                // Reset acknowledge when request is de-asserted
                ack <= 1'b0;
            end
        end
    end

endmodule