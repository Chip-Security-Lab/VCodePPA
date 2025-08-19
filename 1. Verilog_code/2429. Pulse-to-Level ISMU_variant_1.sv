//SystemVerilog
module pulse2level_ismu(
    input wire clock,
    input wire reset_n,
    input wire [3:0] pulse_interrupt,  // interrupt request signals
    input wire req,                    // request signal (replaces clear)
    output reg [3:0] level_interrupt,  // level interrupt signals
    output reg ack                     // acknowledge signal
);
    // Internal state registers
    reg handshake_complete;
    
    // Pipeline registers for interrupt processing
    reg [3:0] pulse_interrupt_r;
    reg [3:0] interrupt_update;
    reg req_r, handshake_complete_r;
    
    // First pipeline stage - register inputs
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pulse_interrupt_r <= 4'h0;
            req_r <= 1'b0;
            handshake_complete_r <= 1'b0;
        end
        else begin
            pulse_interrupt_r <= pulse_interrupt;
            req_r <= req;
            handshake_complete_r <= handshake_complete;
        end
    end
    
    // Second pipeline stage - compute interrupt update logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            interrupt_update <= 4'h0;
        end
        else begin
            if (req_r && !handshake_complete_r) begin
                interrupt_update <= 4'h0;  // Clear interrupts
            end
            else if (!handshake_complete_r) begin
                interrupt_update <= level_interrupt | pulse_interrupt_r;
            end
            else begin
                interrupt_update <= level_interrupt;
            end
        end
    end
    
    // Final stage - update outputs
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            level_interrupt <= 4'h0;
            ack <= 1'b0;
            handshake_complete <= 1'b0;
        end
        else begin
            // Update level_interrupt with the computed value
            level_interrupt <= interrupt_update;
            
            // Handshake logic
            if (req_r && !handshake_complete) begin
                ack <= 1'b1;
                handshake_complete <= 1'b1;
            end
            else if (!req_r && handshake_complete) begin
                ack <= 1'b0;
                handshake_complete <= 1'b0;
            end
        end
    end
endmodule