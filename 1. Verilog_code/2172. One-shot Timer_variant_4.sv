//SystemVerilog
//IEEE 1364-2005
module oneshot_timer (
    input CLK, RST, TRIGGER,
    input [15:0] PERIOD,
    output reg ACTIVE, DONE
);
    reg [15:0] counter;
    wire trigger_edge;
    
    reg trigger_prev;
    
    assign trigger_edge = TRIGGER & ~trigger_prev;
    
    always @(posedge CLK) begin
        if (RST) begin
            trigger_prev <= 1'b0;
        end else begin
            trigger_prev <= TRIGGER;
        end
    end
    
    always @(posedge CLK) begin
        if (RST) begin 
            counter <= 16'd0; 
            ACTIVE <= 1'b0; 
            DONE <= 1'b0;
        end else if (trigger_edge && !ACTIVE) begin 
            ACTIVE <= 1'b1; 
            counter <= 16'd0;
            DONE <= 1'b0;
        end else if (ACTIVE && counter == PERIOD - 1) begin 
            ACTIVE <= 1'b0; 
            DONE <= 1'b1;
            counter <= counter;
        end else if (ACTIVE) begin
            counter <= counter + 16'd1;
            DONE <= 1'b0;
        end else begin
            DONE <= 1'b0;
            counter <= counter;
            ACTIVE <= ACTIVE;
        end
    end
endmodule