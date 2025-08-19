//SystemVerilog
// Top Module
module ITRC_Timeout #(
    parameter TIMEOUT_CYCLES = 100
)(
    input clk,
    input rst_n,
    input int_req,
    input int_ack,
    output reg timeout
);

    // Stage 1 signals
    wire [$clog2(TIMEOUT_CYCLES):0] counter_stage1;
    wire timeout_stage1;
    reg int_req_stage1;
    reg int_ack_stage1;

    // Stage 2 signals
    wire [$clog2(TIMEOUT_CYCLES):0] counter_stage2;
    wire timeout_stage2;
    reg int_req_stage2;
    reg int_ack_stage2;

    // Stage 1 counter
    ITRC_Counter #(
        .TIMEOUT_CYCLES(TIMEOUT_CYCLES)
    ) counter_stage1_inst (
        .clk(clk),
        .rst_n(rst_n),
        .int_req(int_req),
        .int_ack(int_ack),
        .counter(counter_stage1),
        .timeout(timeout_stage1)
    );

    // Stage 1 pipeline registers
    ITRC_Pipeline_Reg #(
        .WIDTH(1)
    ) int_req_reg_stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .din(int_req),
        .dout(int_req_stage1)
    );

    ITRC_Pipeline_Reg #(
        .WIDTH(1)
    ) int_ack_reg_stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .din(int_ack),
        .dout(int_ack_stage1)
    );

    // Stage 2 pipeline registers
    ITRC_Pipeline_Reg #(
        .WIDTH($clog2(TIMEOUT_CYCLES)+1)
    ) counter_reg_stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .din(counter_stage1),
        .dout(counter_stage2)
    );

    ITRC_Pipeline_Reg #(
        .WIDTH(1)
    ) int_req_reg_stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .din(int_req_stage1),
        .dout(int_req_stage2)
    );

    ITRC_Pipeline_Reg #(
        .WIDTH(1)
    ) int_ack_reg_stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .din(int_ack_stage1),
        .dout(int_ack_stage2)
    );

    ITRC_Pipeline_Reg #(
        .WIDTH(1)
    ) timeout_reg_stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .din(timeout_stage1),
        .dout(timeout_stage2)
    );

    // Output stage
    ITRC_Pipeline_Reg #(
        .WIDTH(1)
    ) timeout_output (
        .clk(clk),
        .rst_n(rst_n),
        .din(timeout_stage2),
        .dout(timeout)
    );

endmodule

// Counter Module
module ITRC_Counter #(
    parameter TIMEOUT_CYCLES = 100
)(
    input clk,
    input rst_n,
    input int_req,
    input int_ack,
    output reg [$clog2(TIMEOUT_CYCLES):0] counter,
    output reg timeout
);

    // Counter logic
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
        end else if (int_req && !int_ack) begin
            if (counter < TIMEOUT_CYCLES) begin
                counter <= counter + 1;
            end
        end else begin
            counter <= 0;
        end
    end

    // Timeout logic
    always @(posedge clk) begin
        if (!rst_n) begin
            timeout <= 0;
        end else if (int_req && !int_ack) begin
            timeout <= (counter >= TIMEOUT_CYCLES);
        end else begin
            timeout <= 0;
        end
    end

endmodule

// Pipeline Register Module
module ITRC_Pipeline_Reg #(
    parameter WIDTH = 1
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    always @(posedge clk) begin
        if (!rst_n) begin
            dout <= 0;
        end else begin
            dout <= din;
        end
    end

endmodule