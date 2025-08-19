module ext_clk_precision_timer #(
    parameter WIDTH = 20
)(
    input wire ext_clk,
    input wire sys_clk,
    input wire rst_n,
    input wire start,
    input wire stop,
    output reg busy,
    output reg [WIDTH-1:0] elapsed_time
);
    reg [WIDTH-1:0] counter;
    reg running;
    reg start_sync, start_sync_d;
    reg stop_sync, stop_sync_d;
    
    // Synchronize control signals to ext_clk domain
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            start_sync <= 1'b0;
            start_sync_d <= 1'b0;
            stop_sync <= 1'b0;
            stop_sync_d <= 1'b0;
        end else begin
            start_sync <= start;
            start_sync_d <= start_sync;
            stop_sync <= stop;
            stop_sync_d <= stop_sync;
        end
    end
    
    // External clock domain counter
    always @(posedge ext_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {WIDTH{1'b0}};
            running <= 1'b0;
            busy <= 1'b0;
        end else begin
            if (start_sync_d && !running) begin
                counter <= {WIDTH{1'b0}};
                running <= 1'b1;
                busy <= 1'b1;
            end else if (stop_sync_d && running) begin
                running <= 1'b0;
                elapsed_time <= counter;
                busy <= 1'b0;
            end else if (running) begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule