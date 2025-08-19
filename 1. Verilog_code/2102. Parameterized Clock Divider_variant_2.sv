//SystemVerilog
module param_clock_divider #(
    parameter DIVISOR = 4,
    parameter WIDTH = 32 // $clog2(DIVISOR) replaced for IEEE 1364-2005 compatibility
)(
    input  wire clk_in,
    input  wire rst_n,
    output wire clk_out
);

    // Calculate clog2 for parameter WIDTH at elaboration time
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    localparam COUNTER_WIDTH = (WIDTH == 32) ? clog2(DIVISOR) : WIDTH;

    // Pipeline registers and valid signals
    reg [COUNTER_WIDTH-1:0] counter_stage1;
    reg [COUNTER_WIDTH-1:0] counter_stage2;
    reg [COUNTER_WIDTH-1:0] counter_stage3;
    reg [COUNTER_WIDTH-1:0] next_counter_stage1;
    reg [COUNTER_WIDTH-1:0] next_counter_stage2;
    reg [COUNTER_WIDTH-1:0] next_counter_stage3;
    reg                     toggle_stage1;
    reg                     toggle_stage2;
    reg                     toggle_stage3;

    reg                     clk_out_stage1;
    reg                     clk_out_stage2;
    reg                     clk_out_stage3;
    reg                     clk_out_stage4;

    reg                     valid_stage1;
    reg                     valid_stage2;
    reg                     valid_stage3;
    reg                     valid_stage4;

    reg                     flush_stage1;
    reg                     flush_stage2;
    reg                     flush_stage3;
    reg                     flush_stage4;

    // Pipeline stage 1: Counter increment and toggle calculation
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1      <= {COUNTER_WIDTH{1'b0}};
            next_counter_stage1 <= {COUNTER_WIDTH{1'b0}};
            toggle_stage1       <= 1'b0;
            clk_out_stage1      <= 1'b0;
            valid_stage1        <= 1'b0;
            flush_stage1        <= 1'b1;
        end else begin
            if (flush_stage1) begin
                counter_stage1      <= {COUNTER_WIDTH{1'b0}};
                next_counter_stage1 <= {COUNTER_WIDTH{1'b0}};
                toggle_stage1       <= 1'b0;
                clk_out_stage1      <= 1'b0;
                valid_stage1        <= 1'b0;
            end else begin
                if (counter_stage1 == (DIVISOR-1)) begin
                    next_counter_stage1 <= {COUNTER_WIDTH{1'b0}};
                    toggle_stage1       <= 1'b1;
                end else begin
                    next_counter_stage1 <= counter_stage1 + 1'b1;
                    toggle_stage1       <= 1'b0;
                end
                clk_out_stage1   <= clk_out_stage4;
                valid_stage1     <= 1'b1;
            end
            flush_stage1 <= 1'b0;
        end
    end

    // Pipeline stage 2: Register stage 1 results
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2      <= {COUNTER_WIDTH{1'b0}};
            next_counter_stage2 <= {COUNTER_WIDTH{1'b0}};
            toggle_stage2       <= 1'b0;
            clk_out_stage2      <= 1'b0;
            valid_stage2        <= 1'b0;
            flush_stage2        <= 1'b1;
        end else begin
            if (flush_stage2) begin
                counter_stage2      <= {COUNTER_WIDTH{1'b0}};
                next_counter_stage2 <= {COUNTER_WIDTH{1'b0}};
                toggle_stage2       <= 1'b0;
                clk_out_stage2      <= 1'b0;
                valid_stage2        <= 1'b0;
            end else begin
                counter_stage2      <= next_counter_stage1;
                next_counter_stage2 <= next_counter_stage1;
                toggle_stage2       <= toggle_stage1;
                clk_out_stage2      <= clk_out_stage1;
                valid_stage2        <= valid_stage1;
            end
            flush_stage2 <= flush_stage1;
        end
    end

    // Pipeline stage 3: Register stage 2 results
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage3      <= {COUNTER_WIDTH{1'b0}};
            next_counter_stage3 <= {COUNTER_WIDTH{1'b0}};
            toggle_stage3       <= 1'b0;
            clk_out_stage3      <= 1'b0;
            valid_stage3        <= 1'b0;
            flush_stage3        <= 1'b1;
        end else begin
            if (flush_stage3) begin
                counter_stage3      <= {COUNTER_WIDTH{1'b0}};
                next_counter_stage3 <= {COUNTER_WIDTH{1'b0}};
                toggle_stage3       <= 1'b0;
                clk_out_stage3      <= 1'b0;
                valid_stage3        <= 1'b0;
            end else begin
                counter_stage3      <= next_counter_stage2;
                next_counter_stage3 <= next_counter_stage2;
                toggle_stage3       <= toggle_stage2;
                clk_out_stage3      <= clk_out_stage2;
                valid_stage3        <= valid_stage2;
            end
            flush_stage3 <= flush_stage2;
        end
    end

    // Pipeline stage 4: Output clock update and main counter
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out_stage4   <= 1'b0;
            valid_stage4     <= 1'b0;
            flush_stage4     <= 1'b1;
        end else begin
            if (flush_stage4) begin
                clk_out_stage4   <= 1'b0;
                valid_stage4     <= 1'b0;
            end else if (valid_stage3) begin
                if (toggle_stage3)
                    clk_out_stage4 <= ~clk_out_stage3;
                else
                    clk_out_stage4 <= clk_out_stage3;
                valid_stage4 <= valid_stage3;
            end
            flush_stage4 <= flush_stage3;
        end
    end

    // Flush logic for reset or pipeline flush request
    // Here we flush on reset only; can be extended for dynamic flush
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            flush_stage1 <= 1'b1;
            flush_stage2 <= 1'b1;
            flush_stage3 <= 1'b1;
            flush_stage4 <= 1'b1;
        end else begin
            flush_stage1 <= 1'b0;
            flush_stage2 <= flush_stage1;
            flush_stage3 <= flush_stage2;
            flush_stage4 <= flush_stage3;
        end
    end

    // Assign output
    assign clk_out = clk_out_stage4;

endmodule