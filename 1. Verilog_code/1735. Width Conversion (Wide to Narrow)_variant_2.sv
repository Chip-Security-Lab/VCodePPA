//SystemVerilog
module w2n_bridge #(parameter WIDE=32, NARROW=8) (
    input clk, rst_n,
    input [WIDE-1:0] wide_data,
    input wide_valid,
    output reg wide_ready,
    output reg [NARROW-1:0] narrow_data,
    output reg narrow_valid,
    input narrow_ready
);
    localparam RATIO = WIDE/NARROW;
    
    // Pipeline stage 1: Input capture and buffer
    reg [WIDE-1:0] buffer_stage1;
    reg valid_stage1;
    reg [$clog2(RATIO):0] count_stage1;
    
    // Pipeline stage 2: Data selection and output
    reg [NARROW-1:0] narrow_data_stage2;
    reg valid_stage2;
    reg [$clog2(RATIO):0] count_stage2;
    
    // Reset logic
    always @(posedge clk) begin
        if (!rst_n) begin
            buffer_stage1 <= 0;
            count_stage1 <= 0;
            valid_stage1 <= 0;
            narrow_data_stage2 <= 0;
            valid_stage2 <= 0;
            count_stage2 <= 0;
            wide_ready <= 1;
            narrow_valid <= 0;
        end
    end
    
    // Stage 1: Input capture
    always @(posedge clk) begin
        if (rst_n) begin
            if (wide_valid && wide_ready && count_stage1 == 0) begin
                buffer_stage1 <= wide_data;
                count_stage1 <= 1;
                valid_stage1 <= 1;
                wide_ready <= 0;
            end else if (valid_stage1 && narrow_ready) begin
                if (count_stage1 < RATIO) begin
                    count_stage1 <= count_stage1 + 1;
                end else begin
                    count_stage1 <= 0;
                    valid_stage1 <= 0;
                    wide_ready <= 1;
                end
            end
        end
    end
    
    // Stage 2: Data selection and output
    always @(posedge clk) begin
        if (rst_n) begin
            if (valid_stage1) begin
                narrow_data_stage2 <= buffer_stage1[count_stage1*NARROW +: NARROW];
                valid_stage2 <= 1;
                count_stage2 <= count_stage1;
            end else begin
                valid_stage2 <= 0;
            end
            
            if (valid_stage2 && narrow_ready) begin
                narrow_valid <= 1;
                narrow_data <= narrow_data_stage2;
            end else begin
                narrow_valid <= 0;
            end
        end
    end
endmodule