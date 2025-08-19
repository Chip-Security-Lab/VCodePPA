module freq_divider(
    input wire clk_in, rst_n,
    input wire [15:0] div_ratio,
    input wire update_ratio,
    output reg clk_out
);
    localparam IDLE=1'b0, DIVIDE=1'b1;
    reg state, next;
    reg [15:0] counter;
    reg [15:0] div_value;
    
    always @(posedge clk_in or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            counter <= 16'd0;
            div_value <= 16'd2; // Default divide by 2
            clk_out <= 1'b0;
        end else begin
            state <= next;
            
            if (update_ratio)
                div_value <= (div_ratio < 16'd2) ? 16'd2 : div_ratio;
                
            case (state)
                IDLE: counter <= 16'd0;
                DIVIDE: begin
                    counter <= counter + 16'd1;
                    if (counter >= (div_value/2 - 1)) begin
                        counter <= 16'd0;
                        clk_out <= ~clk_out;
                    end
                end
            endcase
        end
    
    always @(*)
        case (state)
            IDLE: next = DIVIDE;
            DIVIDE: next = DIVIDE;
            default: next = IDLE;
        endcase
endmodule