//SystemVerilog
module bidir_shift_reg #(parameter W = 16) (
    input clock, reset,
    input direction,     // 0: right, 1: left
    input ser_in,
    output ser_out
);
    reg [W-1:0] register;
    reg direction_buf1, direction_buf2;
    reg ser_in_buf;
    reg [W/2-1:0] register_buf_upper, register_buf_lower;
    
    // Buffer control signals to reduce fanout
    always @(posedge clock) begin
        direction_buf1 <= direction;
        direction_buf2 <= direction_buf1;
        ser_in_buf <= ser_in;
    end
    
    // Split the register into two sections for balanced load
    always @(posedge clock) begin
        if (reset) begin
            register <= 0;
            register_buf_upper <= 0;
            register_buf_lower <= 0;
        end
        else if (direction_buf2) begin  // Left shift
            register[W/2-1:0] <= {register[W/2-2:0], ser_in_buf};
            register[W-1:W/2] <= {register[W-2:W/2], register[W/2-1]};
            register_buf_lower <= register[W/2-1:0];
            register_buf_upper <= register[W-1:W/2];
        end
        else begin                  // Right shift
            register[W-1:W/2] <= {ser_in_buf, register[W-1:W/2+1]};
            register[W/2-1:0] <= {register[W/2], register[W/2-1:1]};
            register_buf_lower <= register[W/2-1:0];
            register_buf_upper <= register[W-1:W/2];
        end
    end
    
    // Use buffered register values for output
    reg ser_out_reg;
    always @(posedge clock) begin
        ser_out_reg <= direction_buf2 ? register_buf_upper[W/2-1] : register_buf_lower[0];
    end
    
    assign ser_out = ser_out_reg;
endmodule