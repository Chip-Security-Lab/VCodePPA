//SystemVerilog
module multi_stage_arith_shifter_valid_ready #(
    parameter DATA_WIDTH = 16,
    parameter SHIFT_WIDTH = 4
)(
    input                      clk,
    input                      rst_n,

    // Valid-Ready input interface
    input  [DATA_WIDTH-1:0]    in_value,
    input  [SHIFT_WIDTH-1:0]   shift_amount,
    input                      in_valid,
    output                     in_ready,

    // Valid-Ready output interface
    output [DATA_WIDTH-1:0]    out_value,
    output                     out_valid,
    input                      out_ready
);

    // Stage 1: Input buffer
    reg [DATA_WIDTH-1:0]       in_value_stage1;
    reg [SHIFT_WIDTH-1:0]      shift_amount_stage1;
    reg                        valid_stage1;
    wire                       ready_stage1;

    // Stage 2: First shift (8 bits if shift_amount[3])
    reg [DATA_WIDTH-1:0]       shifted_stage2;
    reg [SHIFT_WIDTH-1:0]      shift_amount_stage2;
    reg                        valid_stage2;
    wire                       ready_stage2;

    // Stage 2.5: Pipeline register to cut critical path
    reg [DATA_WIDTH-1:0]       shifted_stage2_5;
    reg [SHIFT_WIDTH-1:0]      shift_amount_stage2_5;
    reg                        valid_stage2_5;
    wire                       ready_stage2_5;

    // Stage 3: Second shift (4 bits if shift_amount[2])
    reg [DATA_WIDTH-1:0]       shifted_stage3;
    reg [SHIFT_WIDTH-1:0]      shift_amount_stage3;
    reg                        valid_stage3;
    wire                       ready_stage3;

    // Stage 3.5: Pipeline register to cut critical path
    reg [DATA_WIDTH-1:0]       shifted_stage3_5;
    reg [SHIFT_WIDTH-1:0]      shift_amount_stage3_5;
    reg                        valid_stage3_5;
    wire                       ready_stage3_5;

    // Stage 4: Final shift (1-3 bits if shift_amount[1:0])
    reg [DATA_WIDTH-1:0]       shifted_stage4;
    reg                        valid_stage4;

    // Flush logic
    wire                       flush;
    assign flush = ~rst_n;

    // Input ready: stage1 is ready if it is empty or will be consumed
    assign in_ready = ready_stage1;

    // Stage 1: Input Latch
    assign ready_stage1 = ~valid_stage1 | (ready_stage2 & valid_stage1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_value_stage1      <= {DATA_WIDTH{1'b0}};
            shift_amount_stage1  <= {SHIFT_WIDTH{1'b0}};
            valid_stage1         <= 1'b0;
        end else if (flush) begin
            valid_stage1         <= 1'b0;
        end else if (in_valid & ready_stage1) begin
            in_value_stage1      <= in_value;
            shift_amount_stage1  <= shift_amount;
            valid_stage1         <= 1'b1;
        end else if (ready_stage2 & valid_stage1) begin
            valid_stage1         <= 1'b0;
        end
    end

    // Stage 2: First shift (8 bits, controlled by shift_amount[3])
    assign ready_stage2 = ~valid_stage2 | (ready_stage2_5 & valid_stage2);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_stage2       <= {DATA_WIDTH{1'b0}};
            shift_amount_stage2  <= {SHIFT_WIDTH{1'b0}};
            valid_stage2         <= 1'b0;
        end else if (flush) begin
            valid_stage2         <= 1'b0;
        end else if ((valid_stage1 & ready_stage2)) begin
            shifted_stage2       <= shift_amount_stage1[3] ? {{8{in_value_stage1[15]}}, in_value_stage1[15:8]} : in_value_stage1;
            shift_amount_stage2  <= shift_amount_stage1;
            valid_stage2         <= 1'b1;
        end else if (ready_stage2_5 & valid_stage2) begin
            valid_stage2         <= 1'b0;
        end
    end

    // Stage 2.5: Pipeline register to cut the critical path after first shift
    assign ready_stage2_5 = ~valid_stage2_5 | (ready_stage3 & valid_stage2_5);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_stage2_5      <= {DATA_WIDTH{1'b0}};
            shift_amount_stage2_5 <= {SHIFT_WIDTH{1'b0}};
            valid_stage2_5        <= 1'b0;
        end else if (flush) begin
            valid_stage2_5        <= 1'b0;
        end else if ((valid_stage2 & ready_stage2_5)) begin
            shifted_stage2_5      <= shifted_stage2;
            shift_amount_stage2_5 <= shift_amount_stage2;
            valid_stage2_5        <= 1'b1;
        end else if (ready_stage3 & valid_stage2_5) begin
            valid_stage2_5        <= 1'b0;
        end
    end

    // Stage 3: Second shift (4 bits, controlled by shift_amount[2])
    assign ready_stage3 = ~valid_stage3 | (ready_stage3_5 & valid_stage3);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_stage3       <= {DATA_WIDTH{1'b0}};
            shift_amount_stage3  <= {SHIFT_WIDTH{1'b0}};
            valid_stage3         <= 1'b0;
        end else if (flush) begin
            valid_stage3         <= 1'b0;
        end else if ((valid_stage2_5 & ready_stage3)) begin
            shifted_stage3       <= shift_amount_stage2_5[2] ? {{4{shifted_stage2_5[15]}}, shifted_stage2_5[15:4]} : shifted_stage2_5;
            shift_amount_stage3  <= shift_amount_stage2_5;
            valid_stage3         <= 1'b1;
        end else if (ready_stage3_5 & valid_stage3) begin
            valid_stage3         <= 1'b0;
        end
    end

    // Stage 3.5: Pipeline register to cut the critical path after second shift
    assign ready_stage3_5 = ~valid_stage3_5 | (ready_stage4 & valid_stage3_5);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_stage3_5      <= {DATA_WIDTH{1'b0}};
            shift_amount_stage3_5 <= {SHIFT_WIDTH{1'b0}};
            valid_stage3_5        <= 1'b0;
        end else if (flush) begin
            valid_stage3_5        <= 1'b0;
        end else if ((valid_stage3 & ready_stage3_5)) begin
            shifted_stage3_5      <= shifted_stage3;
            shift_amount_stage3_5 <= shift_amount_stage3;
            valid_stage3_5        <= 1'b1;
        end else if (ready_stage4 & valid_stage3_5) begin
            valid_stage3_5        <= 1'b0;
        end
    end

    // Stage 4: Final shift (1~3 bits, controlled by shift_amount[1:0])
    assign ready_stage4 = out_ready | ~valid_stage4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_stage4       <= {DATA_WIDTH{1'b0}};
            valid_stage4         <= 1'b0;
        end else if (flush) begin
            valid_stage4         <= 1'b0;
        end else if (valid_stage3_5 & ready_stage4) begin
            case(shift_amount_stage3_5[1:0])
                2'b00: shifted_stage4 <= shifted_stage3_5;
                2'b01: shifted_stage4 <= {{1{shifted_stage3_5[15]}}, shifted_stage3_5[15:1]};
                2'b10: shifted_stage4 <= {{2{shifted_stage3_5[15]}}, shifted_stage3_5[15:2]};
                2'b11: shifted_stage4 <= {{3{shifted_stage3_5[15]}}, shifted_stage3_5[15:3]};
                default: shifted_stage4 <= shifted_stage3_5;
            endcase
            valid_stage4         <= 1'b1;
        end else if (valid_stage4 & out_ready) begin
            valid_stage4         <= 1'b0;
        end
    end

    // Output assignment
    assign out_value = shifted_stage4;
    assign out_valid = valid_stage4;

endmodule