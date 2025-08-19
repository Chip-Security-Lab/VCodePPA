//SystemVerilog
module crc8_generator #(
    parameter POLY = 8'h07  // CRC-8 polynomial x^8 + x^2 + x + 1
)(
    input        clk,
    input        rst,
    input        enable,
    input        data_in,
    output [7:0] crc_out,
    input        init
);

    // Stage 1: Input synchronization and pipeline
    reg data_in_stage1;
    reg enable_stage1;
    reg init_stage1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_stage1  <= 1'b0;
            enable_stage1   <= 1'b0;
            init_stage1     <= 1'b0;
        end else begin
            data_in_stage1  <= data_in;
            enable_stage1   <= enable;
            init_stage1     <= init;
        end
    end

    // Stage 2: Compute feedback for CRC logic
    reg [7:0] crc_stage2;
    reg       feedback_stage2;
    reg       enable_stage2;
    reg       init_stage2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_stage2      <= 8'h00;
            feedback_stage2 <= 1'b0;
            enable_stage2   <= 1'b0;
            init_stage2     <= 1'b0;
        end else begin
            feedback_stage2 <= crc_stage2[7] ^ data_in_stage1;
            enable_stage2   <= enable_stage1;
            init_stage2     <= init_stage1;
            // Hold crc_stage2 for next stage
        end
    end

    // Stage 3: CRC update (pipeline register)
    reg [7:0] crc_stage3;

    always @(posedge clk or posedge rst) begin
        if (rst)
            crc_stage3 <= 8'h00;
        else if (init_stage2)
            crc_stage3 <= 8'h00;
        else if (enable_stage2) begin
            if (feedback_stage2)
                crc_stage3 <= {crc_stage2[6:0], 1'b0} ^ POLY;
            else
                crc_stage3 <= {crc_stage2[6:0], 1'b0};
        end else
            crc_stage3 <= crc_stage2;
    end

    // Feedback crc_stage3 to crc_stage2 for correct pipelined data flow
    always @(posedge clk or posedge rst) begin
        if (rst)
            crc_stage2 <= 8'h00;
        else
            crc_stage2 <= crc_stage3;
    end

    // Output assignment
    assign crc_out = crc_stage3;

endmodule