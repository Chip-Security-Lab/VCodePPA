module gray_converter(
    input wire clk,
    input wire rst_n,
    input wire [3:0] bin_in,
    output reg [3:0] gray_out
);

    // Pipeline stage 1: Input register
    reg [3:0] bin_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_reg <= 4'b0;
        end else begin
            bin_reg <= bin_in;
        end
    end

    // Pipeline stage 2: Gray conversion logic
    wire [3:0] gray_temp;
    assign gray_temp = bin_reg ^ {1'b0, bin_reg[3:1]};

    // Pipeline stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_out <= 4'b0;
        end else begin
            gray_out <= gray_temp;
        end
    end

endmodule