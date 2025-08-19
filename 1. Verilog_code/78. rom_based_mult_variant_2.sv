//SystemVerilog
module rom_based_mult (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [3:0] addr_a,
    input [3:0] addr_b,
    output reg [7:0] product,
    output reg product_valid
);

    // Internal state
    reg [7:0] rom_data;
    reg [7:0] rom_data_buf;
    reg data_valid;
    reg data_valid_buf;
    
    // ROM lookup table implementation
    always @(*) begin
        case ({addr_a, addr_b})
            // ... existing code ...
            8'h00: rom_data = 8'h00;  // 0 * 0 = 0
            8'h01: rom_data = 8'h00;  // 0 * 1 = 0
            // ... existing code ...
            8'hFF: rom_data = 8'hE1;  // 15 * 15 = 225
            default: rom_data = 8'h00;
        endcase
    end

    // Buffer stage for high fanout signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_data_buf <= 8'h00;
            data_valid_buf <= 1'b0;
        end else begin
            rom_data_buf <= rom_data;
            data_valid_buf <= data_valid;
        end
    end

    // Valid-Ready handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b1;
            product <= 8'h00;
            product_valid <= 1'b0;
            data_valid <= 1'b0;
        end else begin
            if (valid && ready) begin
                product <= rom_data_buf;
                product_valid <= 1'b1;
                ready <= 1'b0;
                data_valid <= 1'b1;
            end else if (!valid) begin
                ready <= 1'b1;
                product_valid <= 1'b0;
                data_valid <= 1'b0;
            end
        end
    end

endmodule