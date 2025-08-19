//SystemVerilog
module decoder_qos #(parameter BURST_SIZE = 4) (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  req,
    output reg  [3:0]  grant
);

    // State encoding for priority selection
    localparam [1:0] STATE_0 = 2'b00;
    localparam [1:0] STATE_1 = 2'b01;
    localparam [1:0] STATE_2 = 2'b10;
    localparam [1:0] STATE_3 = 2'b11;
    
    // Internal signals
    reg [1:0] state_reg;
    reg [1:0] next_state;
    reg [3:0] grant_next;
    
    // State transition logic
    always @(*) begin
        if (state_reg == BURST_SIZE - 1)
            next_state = STATE_0;
        else
            next_state = state_reg + 1'b1;
    end
    
    // Grant generation logic
    always @(*) begin
        case (state_reg)
            STATE_0: grant_next = req & 4'b0001;
            STATE_1: grant_next = req & 4'b0010;
            STATE_2: grant_next = req & 4'b0100;
            STATE_3: grant_next = req & 4'b1000;
            default: grant_next = 4'b0000;
        endcase
    end
    
    // Sequential logic for state and output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= STATE_0;
            grant <= 4'b0000;
        end else begin
            state_reg <= next_state;
            grant <= grant_next;
        end
    end

endmodule