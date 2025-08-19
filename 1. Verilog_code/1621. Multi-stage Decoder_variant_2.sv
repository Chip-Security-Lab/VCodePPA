//SystemVerilog
module two_stage_decoder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid,
    output wire        ready,
    input  wire [3:0]  address,
    output reg  [15:0] select
);

    reg [3:0] stage1_decode;
    reg       data_valid;
    
    // Stage 1: Optimized decode using shift operations
    always @(*) begin
        stage1_decode = 4'b0001 << address[3:2];
    end

    // Stage 2: Optimized decode using shift and mask operations
    always @(*) begin
        select = (stage1_decode << (address[1:0] * 4)) & 16'hFFFF;
    end

    // Valid-Ready handshake control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid <= 1'b0;
        end else begin
            data_valid <= valid;
        end
    end

    assign ready = !data_valid;

endmodule