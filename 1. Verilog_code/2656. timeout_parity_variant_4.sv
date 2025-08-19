//SystemVerilog
module timeout_parity #(
    parameter TIMEOUT = 100
)(
    input clk, rst,
    input data_valid,
    input [15:0] data,
    output reg parity,
    output reg timeout
);

// Data path pipeline registers
typedef struct packed {
    logic [$clog2(TIMEOUT)-1:0] counter;
    logic [15:0] data;
    logic valid;
    logic parity;
    logic timeout;
} pipeline_reg_t;

pipeline_reg_t [2:0] pipeline_reg;

// Stage 1: Input capture and counter
always @(posedge clk) begin
    if (rst) begin
        pipeline_reg[0].counter <= 0;
        pipeline_reg[0].data <= 0;
        pipeline_reg[0].valid <= 0;
    end else begin
        pipeline_reg[0].data <= data;
        pipeline_reg[0].valid <= data_valid;
        pipeline_reg[0].counter <= (data_valid) ? 0 : (pipeline_reg[0].counter + 1);
    end
end

// Stage 2: Data processing and parity
always @(posedge clk) begin
    if (rst) begin
        pipeline_reg[1] <= '0;
    end else begin
        pipeline_reg[1].counter <= pipeline_reg[0].counter;
        pipeline_reg[1].data <= pipeline_reg[0].data;
        pipeline_reg[1].valid <= pipeline_reg[0].valid;
        pipeline_reg[1].parity <= ^pipeline_reg[0].data;
    end
end

// Stage 3: Output generation
always @(posedge clk) begin
    if (rst) begin
        pipeline_reg[2] <= '0;
    end else begin
        pipeline_reg[2].parity <= pipeline_reg[1].parity;
        pipeline_reg[2].timeout <= (pipeline_reg[1].valid) ? 0 : 
                                 (pipeline_reg[1].counter == TIMEOUT-1) ? 1 : 
                                 pipeline_reg[2].timeout;
    end
end

// Output assignments
assign parity = pipeline_reg[2].parity;
assign timeout = pipeline_reg[2].timeout;

endmodule