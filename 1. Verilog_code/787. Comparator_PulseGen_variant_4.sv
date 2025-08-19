//SystemVerilog
module Comparator_PulseGen #(parameter WIDTH = 8) (
    input              clk,
    input              rst_n,
    input              valid_in,
    output reg         ready_out,
    input  [WIDTH-1:0] data_x,
    input  [WIDTH-1:0] data_y,
    output reg         change_pulse,
    output reg         valid_out
);

    // Clock buffering
    wire clk_buf1, clk_buf2, clk_buf3;
    ClockBuffer clk_buffer_inst1 (.clk_in(clk), .clk_out(clk_buf1));
    ClockBuffer clk_buffer_inst2 (.clk_in(clk), .clk_out(clk_buf2));
    ClockBuffer clk_buffer_inst3 (.clk_in(clk), .clk_out(clk_buf3));

    // Pipeline stage 1: Comparison
    reg [WIDTH-1:0] data_x_stage1, data_y_stage1;
    reg valid_stage1;
    wire equal_stage1 = (data_x_stage1 == data_y_stage1);
    
    // Buffered valid_stage1 for high fanout
    reg valid_stage1_buf1, valid_stage1_buf2;
    
    // Pipeline stage 2: Edge detection
    reg equal_stage2;
    reg valid_stage2;
    reg last_state;
    
    // Pipeline control with buffered signals
    wire stage1_ready = !valid_stage1_buf1 || valid_out;
    wire stage2_ready = !valid_stage2 || valid_out;
    
    // Stage 1: Comparison with buffered clock
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            data_x_stage1 <= {WIDTH{1'b0}};
            data_y_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (valid_in && stage1_ready) begin
            data_x_stage1 <= data_x;
            data_y_stage1 <= data_y;
            valid_stage1 <= 1'b1;
        end else if (!valid_in && stage1_ready) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Buffers for valid_stage1 signal (high fanout)
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1_buf1 <= 1'b0;
            valid_stage1_buf2 <= 1'b0;
        end else begin
            valid_stage1_buf1 <= valid_stage1;
            valid_stage1_buf2 <= valid_stage1;
        end
    end
    
    // Equal comparison result buffering
    reg b0, b1; // Buffer registers for equal_stage1
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            b0 <= 1'b0;
            b1 <= 1'b0;
        end else begin
            b0 <= equal_stage1;
            b1 <= b0;
        end
    end
    
    // Stage 2: Edge detection with buffered signals
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            equal_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            last_state <= 1'b0;
        end else if (valid_stage1_buf1 && stage2_ready) begin
            equal_stage2 <= b1; // Use buffered comparison result
            valid_stage2 <= 1'b1;
            last_state <= equal_stage2;
        end else if (!valid_stage1_buf1 && stage2_ready) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Output stage with dedicated clock buffer
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n) begin
            change_pulse <= 1'b0;
            valid_out <= 1'b0;
        end else if (valid_stage2) begin
            change_pulse <= (equal_stage2 != last_state);
            valid_out <= 1'b1;
        end else begin
            change_pulse <= 1'b0;
            valid_out <= 1'b0;
        end
    end
    
    // Ready signal generation
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n) begin
            ready_out <= 1'b1;
        end else begin
            ready_out <= stage1_ready;
        end
    end
    
endmodule

// Clock buffer module to reduce fanout load of clock
module ClockBuffer (
    input  clk_in,
    output clk_out
);
    // Simple non-inverting buffer
    assign clk_out = clk_in;
endmodule