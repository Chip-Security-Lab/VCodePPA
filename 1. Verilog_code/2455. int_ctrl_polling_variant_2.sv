//SystemVerilog
module int_ctrl_polling #(
    parameter CNT_W = 3
)(
    input                   clk,
    input                   enable,
    input  [2**CNT_W-1:0]   int_src,
    output                  int_valid,
    output [CNT_W-1:0]      int_id
);

    // Internal pipeline registers
    reg [CNT_W-1:0]         poll_counter_r;
    reg [CNT_W-1:0]         int_id_r;
    reg                     int_valid_r;
    reg [2**CNT_W-1:0]      int_src_r;
    
    // Combined always block for both stages
    always @(posedge clk) begin
        // Stage 1: Counter update logic and input registration
        if (enable) begin
            poll_counter_r <= poll_counter_r + 1'b1;
        end
        int_src_r <= int_src;
        
        // Stage 2: Interrupt detection
        int_valid_r <= int_src_r[poll_counter_r];
        int_id_r <= poll_counter_r;
    end
    
    // Output assignments
    assign int_valid = int_valid_r;
    assign int_id = int_id_r;

endmodule