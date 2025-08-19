//SystemVerilog
module decoder_err_detect #(
    parameter MAX_ADDR = 16'hFFFF,
    parameter ADDR_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg select,
    output reg err
);

    // Pipeline stage 1: Address comparison
    reg addr_valid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_valid <= 1'b0;
        end else begin
            addr_valid <= (addr < MAX_ADDR);
        end
    end

    // Pipeline stage 2: Error detection
    reg addr_err;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_err <= 1'b0;
        end else begin
            addr_err <= (addr >= MAX_ADDR);
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select <= 1'b0;
            err <= 1'b0;
        end else begin
            select <= addr_valid;
            err <= addr_err;
        end
    end

endmodule