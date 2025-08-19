//SystemVerilog
// Input stage module
module base_addr_decoder_input_stage (
    input clk,
    input rst_n,
    input valid_in,
    output reg ready_out,
    input [3:0] addr,
    output reg [3:0] addr_out,
    output reg valid_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_out <= 4'h0;
            valid_out <= 1'b0;
            ready_out <= 1'b1;
        end else begin
            if (valid_in && ready_out) begin
                addr_out <= addr;
                valid_out <= 1'b1;
            end else if (!valid_in) begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule

// Address comparison stage module
module base_addr_decoder_compare_stage (
    input clk,
    input rst_n,
    input valid_in,
    input [3:0] addr_in,
    output reg [1:0] addr_high_out,
    output reg valid_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_high_out <= 2'h0;
            valid_out <= 1'b0;
        end else begin
            if (valid_in) begin
                addr_high_out <= addr_in[3:2];
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule

// Output stage module
module base_addr_decoder_output_stage #(
    parameter BASE_ADDR = 4'h0
)(
    input clk,
    input rst_n,
    input valid_in,
    input [1:0] addr_high_in,
    output reg cs,
    output reg valid_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cs <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            if (valid_in) begin
                cs <= (addr_high_in == BASE_ADDR[3:2]);
                valid_out <= 1'b1;
            end else begin
                cs <= 1'b0;
                valid_out <= 1'b0;
            end
        end
    end

endmodule

// Top-level module
module base_addr_decoder #(
    parameter BASE_ADDR = 4'h0
)(
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [3:0] addr,
    output cs,
    output valid_out
);

    // Internal signals
    wire [3:0] addr_stage1;
    wire valid_stage1;
    wire [1:0] addr_high_stage2;
    wire valid_stage2;

    // Instantiate input stage
    base_addr_decoder_input_stage input_stage (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .addr(addr),
        .addr_out(addr_stage1),
        .valid_out(valid_stage1)
    );

    // Instantiate compare stage
    base_addr_decoder_compare_stage compare_stage (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage1),
        .addr_in(addr_stage1),
        .addr_high_out(addr_high_stage2),
        .valid_out(valid_stage2)
    );

    // Instantiate output stage
    base_addr_decoder_output_stage #(
        .BASE_ADDR(BASE_ADDR)
    ) output_stage (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage2),
        .addr_high_in(addr_high_stage2),
        .cs(cs),
        .valid_out(valid_out)
    );

endmodule