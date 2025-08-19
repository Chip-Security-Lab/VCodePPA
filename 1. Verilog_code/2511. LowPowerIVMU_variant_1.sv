//SystemVerilog
module LowPowerIVMU (
    input main_clk, rst_n,
    input [15:0] int_sources,
    input [15:0] int_mask,
    input clk_en,
    output reg [31:0] vector_out,
    output reg int_pending
);
    wire gated_clk;
    reg [31:0] vectors [0:15];
    wire [15:0] pending;

    assign gated_clk = main_clk & (clk_en | |pending);
    assign pending = int_sources & ~int_mask;

    initial begin
        vectors[0] = 32'h9000_0000;
        vectors[1] = 32'h9000_0004;
        vectors[2] = 32'h9000_0008;
        vectors[3] = 32'h9000_000C;
        vectors[4] = 32'h9000_0010;
        vectors[5] = 32'h9000_0014;
        vectors[6] = 32'h9000_0018;
        vectors[7] = 32'h9000_001C;
        vectors[8] = 32'h9000_0020;
        vectors[9] = 32'h9000_0024;
        vectors[10] = 32'h9000_0028;
        vectors[11] = 32'h9000_002C;
        vectors[12] = 32'h9000_0030;
        vectors[13] = 32'h9000_0034;
        vectors[14] = 32'h9000_0038;
        vectors[15] = 32'h9000_003C;
    end

    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            vector_out <= 32'h0;
            int_pending <= 1'b0;
        end else begin
            int_pending <= |pending;
            if (|pending) begin // Only update vector_out if there is a pending interrupt
                casez (pending)
                    16'b1???????????????: vector_out <= vectors[15];
                    16'b01??????????????: vector_out <= vectors[14];
                    16'b001?????????????: vector_out <= vectors[13];
                    16'b0001????????????: vector_out <= vectors[12];
                    16'b00001???????????: vector_out <= vectors[11];
                    16'b000001??????????: vector_out <= vectors[10];
                    16'b0000001?????????: vector_out <= vectors[9];
                    16'b00000001????????: vector_out <= vectors[8];
                    16'b000000001???????: vector_out <= vectors[7];
                    16'b0000000001??????: vector_out <= vectors[6];
                    16'b00000000001????? : vector_out <= vectors[5];
                    16'b000000000001????: vector_out <= vectors[4];
                    16'b0000000000001???: vector_out <= vectors[3];
                    16'b00000000000001??: vector_out <= vectors[2];
                    16'b000000000000001?: vector_out <= vectors[1];
                    16'b0000000000000001: vector_out <= vectors[0];
                    // No default needed as the case is inside the `if (|pending)` block.
                    // If |pending is 0, this case block is skipped,
                    // and vector_out retains its previous value.
                endcase
            end
        end
    end
endmodule