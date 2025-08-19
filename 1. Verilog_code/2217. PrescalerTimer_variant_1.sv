//SystemVerilog
module PrescalerTimer #(
    parameter PRESCALE = 8
)(
    input  wire clk,
    input  wire rst_n,
    output reg  tick
);

    // Local parameters
    localparam CNT_WIDTH = $clog2(PRESCALE);
    
    // Registers
    reg [CNT_WIDTH-1:0] ps_cnt_r;
    reg                 tick_pre_r;
    
    // Combinational logic signals
    wire                terminal_count;
    wire [CNT_WIDTH-1:0] ps_cnt_next;
    
    //--------------------------------------------------
    // Combinational Logic Block
    //--------------------------------------------------
    
    // Terminal count detection
    assign terminal_count = (ps_cnt_r == PRESCALE-1);
    
    // Next counter value calculation
    assign ps_cnt_next = terminal_count ? {CNT_WIDTH{1'b0}} : ps_cnt_r + 1'b1;
    
    //--------------------------------------------------
    // Sequential Logic Block
    //--------------------------------------------------
    
    // Counter register update
    always @(posedge clk) begin
        if (!rst_n) begin
            ps_cnt_r <= {CNT_WIDTH{1'b0}};
        end else begin
            ps_cnt_r <= ps_cnt_next;
        end
    end
    
    // Pipeline stage 1: Pre-tick generation
    always @(posedge clk) begin
        if (!rst_n) begin
            tick_pre_r <= 1'b0;
        end else begin
            tick_pre_r <= terminal_count;
        end
    end
    
    // Pipeline stage 2: Output tick generation
    always @(posedge clk) begin
        if (!rst_n) begin
            tick <= 1'b0;
        end else begin
            tick <= tick_pre_r;
        end
    end

endmodule