module wave19_beep #(
    parameter BEEP_ON  = 50,
    parameter BEEP_OFF = 50,
    parameter WIDTH    = 8
)(
    input  wire clk,
    input  wire rst,
    output reg  beep_out
);
    reg [WIDTH-1:0] cnt;
    reg             state;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt      <= 0;
            state    <= 0;
            beep_out <= 0;
        end else begin
            cnt <= cnt + 1;
            if(!state && cnt == BEEP_ON) begin
                state    <= 1;
                cnt      <= 0;
                beep_out <= 0;
            end else if(state && cnt == BEEP_OFF) begin
                state    <= 0;
                cnt      <= 0;
                beep_out <= 1;
            end
        end
    end
endmodule

