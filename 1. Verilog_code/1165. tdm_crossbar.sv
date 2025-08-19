module tdm_crossbar (
    input wire clock, reset,
    input wire [7:0] in0, in1, in2, in3,
    output reg [7:0] out0, out1, out2, out3
);
    // Time-division multiplexed crossbar using fixed schedule
    reg [1:0] time_slot;  // Current time slot
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            time_slot <= 2'b00;
            out0 <= 8'h00;
            out1 <= 8'h00;
            out2 <= 8'h00;
            out3 <= 8'h00;
        end else begin
            // Rotate time slot on each clock
            time_slot <= time_slot + 1'b1;
            
            // Schedule: 
            // Slot 0: in0->out0, in1->out1, in2->out2, in3->out3
            // Slot 1: in0->out1, in1->out2, in2->out3, in3->out0
            // Slot 2: in0->out2, in1->out3, in2->out0, in3->out1
            // Slot 3: in0->out3, in1->out0, in2->out1, in3->out2
            case (time_slot)
                2'b00: begin
                    out0 <= in0; out1 <= in1; 
                    out2 <= in2; out3 <= in3;
                end
                2'b01: begin
                    out0 <= in3; out1 <= in0; 
                    out2 <= in1; out3 <= in2;
                end
                2'b10: begin
                    out0 <= in2; out1 <= in3; 
                    out2 <= in0; out3 <= in1;
                end
                2'b11: begin
                    out0 <= in1; out1 <= in2; 
                    out2 <= in3; out3 <= in0;
                end
            endcase
        end
    end
endmodule