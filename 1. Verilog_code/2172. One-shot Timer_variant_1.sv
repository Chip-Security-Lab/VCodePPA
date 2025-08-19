//SystemVerilog
module oneshot_timer (
    input CLK, RST, TRIGGER,
    input [15:0] PERIOD,
    output reg ACTIVE, DONE
);
    reg [15:0] counter;
    reg trigger_d;
    wire trigger_edge;
    wire [15:0] counter_next;
    
    // Carry Look-Ahead Adder signals
    wire [15:0] G, P;  // Generate and Propagate signals
    wire [16:0] C;     // Carry signals (including initial carry)
    
    always @(posedge CLK) trigger_d <= TRIGGER;
    assign trigger_edge = TRIGGER & ~trigger_d;
    
    // Generate and Propagate signals for CLA
    assign G = counter & 16'd1;
    assign P = counter | 16'd1;
    
    // Carry calculation for Carry-Look-Ahead Adder
    assign C[0] = 1'b0;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & C[1]);
    assign C[3] = G[2] | (P[2] & C[2]);
    assign C[4] = G[3] | (P[3] & C[3]);
    assign C[5] = G[4] | (P[4] & C[4]);
    assign C[6] = G[5] | (P[5] & C[5]);
    assign C[7] = G[6] | (P[6] & C[6]);
    assign C[8] = G[7] | (P[7] & C[7]);
    assign C[9] = G[8] | (P[8] & C[8]);
    assign C[10] = G[9] | (P[9] & C[9]);
    assign C[11] = G[10] | (P[10] & C[10]);
    assign C[12] = G[11] | (P[11] & C[11]);
    assign C[13] = G[12] | (P[12] & C[12]);
    assign C[14] = G[13] | (P[13] & C[13]);
    assign C[15] = G[14] | (P[14] & C[14]);
    assign C[16] = G[15] | (P[15] & C[15]);
    
    // Sum calculation using CLA
    assign counter_next = counter ^ {C[15:0]};
    
    always @(posedge CLK) begin
        if (RST) begin 
            counter <= 16'd0; 
            ACTIVE <= 1'b0; 
            DONE <= 1'b0; 
        end
        else begin
            DONE <= 1'b0;
            if (trigger_edge && !ACTIVE) begin 
                ACTIVE <= 1'b1; 
                counter <= 16'd0; 
            end
            if (ACTIVE) begin
                counter <= counter_next;
                if (counter == PERIOD - 1) begin 
                    ACTIVE <= 1'b0; 
                    DONE <= 1'b1; 
                end
            end
        end
    end
endmodule