//SystemVerilog
module reset_with_ack(
    input wire clk,
    input wire reset_req,
    input wire [3:0] ack_signals,
    output wire [3:0] reset_out,
    output wire reset_complete
);
    // Clock buffer tree for high fanout clock
    wire clk_buf1, clk_buf2, clk_buf3;
    
    BUFG clock_buffer1 (.I(clk), .O(clk_buf1));
    BUFG clock_buffer2 (.I(clk_buf1), .O(clk_buf2));
    BUFG clock_buffer3 (.I(clk_buf1), .O(clk_buf3));
    
    // Internal connections between pipeline stages
    wire reset_req_stage1, reset_req_stage2;
    wire [3:0] ack_signals_stage1, ack_signals_stage2;
    wire [3:0] reset_out_stage1;
    wire reset_complete_stage1;
    
    // Input stage - handles input registration
    input_stage u_input_stage (
        .clk(clk_buf2),
        .reset_req_in(reset_req),
        .ack_signals_in(ack_signals),
        .reset_req_out(reset_req_stage1),
        .ack_signals_out(ack_signals_stage1),
        .reset_out(reset_out_stage1),
        .reset_complete(reset_complete_stage1)
    );
    
    // Processing stage - handles acknowledgment logic
    processing_stage u_processing_stage (
        .clk(clk_buf3),
        .reset_req_in(reset_req_stage1),
        .ack_signals_in(ack_signals_stage1),
        .reset_out_in(reset_out_stage1),
        .reset_complete_in(reset_complete_stage1),
        .reset_req_out(reset_req_stage2),
        .ack_signals_out(ack_signals_stage2),
        .reset_out(reset_out),
        .reset_complete(reset_complete)
    );
endmodule

// Buffer module for clock tree
module BUFG (
    input wire I,
    output wire O
);
    assign O = I;
endmodule

// Input stage module - first pipeline stage
module input_stage (
    input wire clk,
    input wire reset_req_in,
    input wire [3:0] ack_signals_in,
    output reg reset_req_out,
    output reg [3:0] ack_signals_out,
    output reg [3:0] reset_out,
    output reg reset_complete
);
    // Buffers for high fanout signals
    reg reset_req_buf1, reset_req_buf2;
    reg [3:0] ack_signals_buf1, ack_signals_buf2;
    
    always @(posedge clk) begin
        // Buffer inputs to reduce fanout
        reset_req_buf1 <= reset_req_in;
        reset_req_buf2 <= reset_req_buf1;
        reset_req_out <= reset_req_buf2;
        
        ack_signals_buf1 <= ack_signals_in;
        ack_signals_buf2 <= ack_signals_buf1;
        ack_signals_out <= ack_signals_buf2;
        
        // Initial reset detection logic with balanced load
        if (reset_req_buf2) begin
            reset_out <= 4'hF;
            reset_complete <= 1'b0;
        end
    end
endmodule

// Processing stage module - second and third pipeline stages combined
module processing_stage (
    input wire clk,
    input wire reset_req_in,
    input wire [3:0] ack_signals_in,
    input wire [3:0] reset_out_in,
    input wire reset_complete_in,
    output reg reset_req_out,
    output reg [3:0] ack_signals_out,
    output reg [3:0] reset_out,
    output reg reset_complete
);
    // Internal signals for intermediate stage
    reg [3:0] reset_out_internal;
    reg reset_complete_internal;
    
    // Buffers for high fanout signals
    reg reset_req_buf;
    reg [3:0] ack_signals_buf;
    reg [3:0] reset_out_buf;
    reg reset_complete_buf;
    
    // Split reset_out into groups to reduce fanout
    reg [1:0] reset_out_group1;
    reg [1:0] reset_out_group2;

    // Pipeline stage 2: Process acknowledgment
    always @(posedge clk) begin
        // Buffer inputs to reduce fanout
        reset_req_buf <= reset_req_in;
        reset_req_out <= reset_req_buf;
        
        ack_signals_buf <= ack_signals_in;
        ack_signals_out <= ack_signals_buf;
        
        // Process acknowledgment logic for stage 2
        if (reset_req_buf) begin
            reset_out_internal <= 4'hF;
            reset_complete_internal <= 1'b0;
        end else if (ack_signals_buf == 4'hF) begin
            reset_out_internal <= 4'h0;
            reset_complete_internal <= 1'b1;
        end else begin
            reset_out_internal <= reset_out_in;
            reset_complete_internal <= reset_complete_in;
        end
    end
    
    // Pipeline stage 3: Final output stage with buffered signals
    always @(posedge clk) begin
        // Buffer intermediate results
        reset_out_buf <= reset_out_internal;
        reset_complete_buf <= reset_complete_internal;
        
        // Split reset_out into groups to balance load
        reset_out_group1 <= {reset_out_buf[1:0]};
        reset_out_group2 <= {reset_out_buf[3:2]};
        
        // Final output assignments
        if (reset_req_out) begin
            reset_out[1:0] <= 2'b11;
            reset_out[3:2] <= 2'b11;
            reset_complete <= 1'b0;
        end else if (ack_signals_out == 4'hF) begin
            reset_out[1:0] <= 2'b00;
            reset_out[3:2] <= 2'b00;
            reset_complete <= 1'b1;
        end else begin
            reset_out[1:0] <= reset_out_group1;
            reset_out[3:2] <= reset_out_group2;
            reset_complete <= reset_complete_buf;
        end
    end
endmodule