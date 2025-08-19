//SystemVerilog
module async_duty_pulse(
    input clk,
    input arst,
    input [7:0] period,
    input [2:0] duty_sel,  // 0-7 representing duty cycles
    output reg pulse
);
    reg [7:0] counter;
    reg [7:0] duty_threshold;
    
    // 专门处理duty_threshold的always块
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            duty_threshold <= 8'd0;
        end else begin
            case (duty_sel)
                3'd0: duty_threshold <= {1'b0, period[7:1]};      // 50%
                3'd1: duty_threshold <= {2'b00, period[7:2]};     // 25%
                3'd2: duty_threshold <= {3'b000, period[7:3]};    // 12.5%
                3'd3: duty_threshold <= {2'b00, period[7:2]} + {1'b0, period[7:1]}; // 75%
                3'd4: duty_threshold <= {3'b000, period[7:3]} + {1'b0, period[7:1]}; // 62.5%
                3'd5: duty_threshold <= {3'b000, period[7:3]} + {2'b00, period[7:2]}; // 37.5%
                3'd6: duty_threshold <= period - 8'd1;           // 99%
                3'd7: duty_threshold <= 8'd1;                    // 1%
            endcase
        end
    end
    
    // 专门处理counter的always块
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            counter <= 8'd0;
        end else begin
            if (counter >= period-1)
                counter <= 8'd0;
            else
                counter <= counter + 8'd1;
        end
    end
    
    // 专门处理pulse输出的always块
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            pulse <= 1'b0;
        end else begin
            pulse <= (counter < duty_threshold) ? 1'b1 : 1'b0;
        end
    end
endmodule