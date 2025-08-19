module mux4to1_pipelined(
    input clk,
    input rst_n,
    input [3:0] data_in,
    input [1:0] sel_in,
    output reg data_out
);

    // Pipeline registers
    reg [3:0] data_reg;
    reg [1:0] sel_reg;
    reg [3:0] mux_result;
    
    // Stage 1: Input Register - Data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 4'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    // Stage 1: Input Register - Select
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_reg <= 2'b0;
        end else begin
            sel_reg <= sel_in;
        end
    end
    
    // Stage 2: Mux Logic
    always @(*) begin
        case(sel_reg)
            2'b00: mux_result = {3'b0, data_reg[0]};
            2'b01: mux_result = {2'b0, data_reg[1], 1'b0};
            2'b10: mux_result = {1'b0, data_reg[2], 2'b0};
            2'b11: mux_result = {data_reg[3], 3'b0};
        endcase
    end

    // Stage 2: Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
        end else begin
            data_out <= |mux_result;
        end
    end

endmodule