//SystemVerilog
module counter_preload #(parameter WIDTH=4) (
    input clk, load, en,
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] cnt
);
    reg load_r, en_r;
    reg [WIDTH-1:0] data_r;
    reg [WIDTH-1:0] next_cnt;
    
    // Create a control signal for case statement
    reg [1:0] ctrl;

    // Register control signals and data input
    always @(posedge clk) begin
        load_r <= load;
        en_r <= en;
        data_r <= data;
    end

    // Encode control signals
    always @(*) begin
        ctrl = {load_r, en_r};
    end

    // Calculate next counter value using case statement
    always @(*) begin
        case(ctrl)
            2'b10, 2'b11: next_cnt = data_r;    // load_r=1, en_r=any
            2'b01:        next_cnt = cnt + 1;   // load_r=0, en_r=1
            2'b00:        next_cnt = cnt;       // load_r=0, en_r=0
            default:      next_cnt = cnt;       // For simulation completeness
        endcase
    end

    // Update counter output
    always @(posedge clk) begin
        cnt <= next_cnt;
    end
endmodule