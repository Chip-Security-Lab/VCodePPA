//SystemVerilog
module serial_to_parallel #(
    parameter WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  en,
    input  wire                  serial_in,
    output reg  [WIDTH-1:0]      parallel_out,
    output reg                   done
);

    // Stage 1: Capture serial_in and en, manage count
    reg [$clog2(WIDTH):0]        count_stage1;
    reg                          en_stage1;
    reg                          serial_in_stage1;
    reg  [WIDTH-1:0]             parallel_shift_stage1;
    reg                          valid_stage1;

    // Stage 2: Register outputs
    reg [$clog2(WIDTH):0]        count_stage2;
    reg  [WIDTH-1:0]             parallel_shift_stage2;
    reg                          done_stage2;
    reg                          valid_stage2;

    // Stage 1: Collect serial input and update count/shift register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage1         <= 0;
            parallel_shift_stage1<= 0;
            en_stage1            <= 0;
            serial_in_stage1     <= 0;
            valid_stage1         <= 0;
        end else begin
            en_stage1        <= en;
            serial_in_stage1 <= serial_in;
            if (en) begin
                if (count_stage1 == WIDTH) begin
                    count_stage1          <= 0;
                    parallel_shift_stage1 <= parallel_shift_stage1; // Hold value
                    valid_stage1          <= 1;
                end else begin
                    parallel_shift_stage1 <= {parallel_shift_stage1[WIDTH-2:0], serial_in};
                    count_stage1          <= count_stage1 + 1;
                    valid_stage1          <= 0;
                end
            end else begin
                valid_stage1 <= 0;
            end
        end
    end

    // Stage 2: Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage2           <= 0;
            parallel_shift_stage2  <= 0;
            done_stage2            <= 0;
            valid_stage2           <= 0;
        end else begin
            count_stage2          <= count_stage1;
            parallel_shift_stage2 <= parallel_shift_stage1;
            valid_stage2          <= valid_stage1;

            if (valid_stage1 && (count_stage1 == WIDTH)) begin
                done_stage2           <= 1;
            end else begin
                done_stage2           <= 0;
            end
        end
    end

    // Output assignments
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_out <= 0;
            done         <= 0;
        end else begin
            if (valid_stage2 && (count_stage2 == WIDTH)) begin
                parallel_out <= parallel_shift_stage2;
                done         <= done_stage2;
            end else begin
                done         <= 0;
            end
        end
    end

endmodule