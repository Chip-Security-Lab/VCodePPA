//SystemVerilog
module int_ctrl_polling #(
    parameter CNT_W = 3
)(
    input  wire                clk,
    input  wire                enable,
    input  wire [2**CNT_W-1:0] int_src,
    output wire                int_valid,
    output wire [CNT_W-1:0]    int_id
);
    wire [CNT_W-1:0] poll_counter;
    wire [CNT_W-1:0] poll_counter_pipe;
    wire [2**CNT_W-1:0] int_src_pipe;
    
    // Counter management module instance
    counter_manager #(
        .CNT_W(CNT_W)
    ) counter_inst (
        .clk(clk),
        .enable(enable),
        .int_src(int_src),
        .poll_counter(poll_counter),
        .poll_counter_pipe(poll_counter_pipe),
        .int_src_pipe(int_src_pipe)
    );
    
    // Interrupt validation module instance
    interrupt_validator #(
        .CNT_W(CNT_W)
    ) validator_inst (
        .clk(clk),
        .poll_counter_pipe(poll_counter_pipe),
        .int_src_pipe(int_src_pipe),
        .int_valid(int_valid),
        .int_id(int_id)
    );
endmodule

// Counter management module
module counter_manager #(
    parameter CNT_W = 3
)(
    input  wire                clk,
    input  wire                enable,
    input  wire [2**CNT_W-1:0] int_src,
    output reg  [CNT_W-1:0]    poll_counter,
    output reg  [CNT_W-1:0]    poll_counter_pipe,
    output reg  [2**CNT_W-1:0] int_src_pipe
);
    // Counter control logic
    always @(posedge clk) begin
        if (!enable) begin
            // Hold counter value when polling is disabled
            poll_counter <= poll_counter;
        end else begin
            // Always increment counter regardless of interrupt state
            poll_counter <= poll_counter + 1'b1;
        end
        
        // Pipeline registers
        poll_counter_pipe <= poll_counter;
        int_src_pipe <= int_src;
    end
endmodule

// Interrupt validation module
module interrupt_validator #(
    parameter CNT_W = 3
)(
    input  wire                clk,
    input  wire [CNT_W-1:0]    poll_counter_pipe,
    input  wire [2**CNT_W-1:0] int_src_pipe,
    output reg                 int_valid,
    output wire [CNT_W-1:0]    int_id
);
    // Interrupt validation logic
    always @(posedge clk) begin
        int_valid <= int_src_pipe[poll_counter_pipe];
    end
    
    // Dedicated output assignment
    assign int_id = poll_counter_pipe;
endmodule