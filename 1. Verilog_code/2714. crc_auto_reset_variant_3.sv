//SystemVerilog
module crc_auto_reset #(parameter MAX_COUNT=255)(
    input clk, start,
    input [7:0] data_stream,
    output reg [15:0] crc,
    output done
);
    reg [8:0] counter;
    reg [1:0] state;
    
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    function [15:0] crc_next;
        input [15:0] crc_in;
        input [7:0] data;
        begin
            crc_next = {crc_in[14:0], 1'b0} ^ 
                    (crc_in[15] ? 16'h8005 : 16'h0000) ^ 
                    {8'h00, data};
        end
    endfunction

    always @(posedge clk) begin
        case(state)
            IDLE: begin
                if(start) begin
                    counter <= 0;
                    crc <= 16'hFFFF;
                    state <= CALC;
                end
            end
            
            CALC: begin
                if(counter < MAX_COUNT) begin
                    crc <= crc_next(crc, data_stream);
                    counter <= counter + 1;
                end else begin
                    state <= DONE;
                end
            end
            
            DONE: begin
                if(start) begin
                    counter <= 0;
                    crc <= 16'hFFFF;
                    state <= CALC;
                end
            end
            
            default: state <= IDLE;
        endcase
    end

    assign done = (state == DONE);
endmodule