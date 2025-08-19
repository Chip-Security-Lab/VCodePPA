//SystemVerilog
//IEEE 1364-2005
module RingScheduler #(parameter BUF_SIZE=8) (
    input wire clk,
    input wire rst_n,
    output wire [BUF_SIZE-1:0] events
);
    // Internal connections
    wire [2:0] current_ptr;
    wire [BUF_SIZE-1:0] next_events;
    
    // Clock and reset buffers for fan-out reduction
    wire clk_buf1, clk_buf2, clk_buf3;
    wire rst_n_buf1, rst_n_buf2, rst_n_buf3;
    
    // Clock buffer tree
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    assign clk_buf3 = clk;
    
    // Reset buffer tree
    assign rst_n_buf1 = rst_n;
    assign rst_n_buf2 = rst_n;
    assign rst_n_buf3 = rst_n;

    // Event signal buffers
    reg [BUF_SIZE-1:0] next_events_buf1;
    reg [BUF_SIZE-1:0] current_events_buf1;
    
    // Buffer for events feedback to EventRotator
    always @(posedge clk_buf1) begin
        current_events_buf1 <= events;
    end
    
    // Buffer for next_events
    always @(posedge clk_buf1) begin
        next_events_buf1 <= next_events;
    end
    
    // Counter module for tracking position
    PtrCounter #(
        .PTR_WIDTH(3)
    ) ptr_counter_inst (
        .clk(clk_buf1),
        .rst_n(rst_n_buf1),
        .ptr_out(current_ptr)
    );
    
    // Event rotation logic module
    EventRotator #(
        .BUF_SIZE(BUF_SIZE)
    ) event_rotator_inst (
        .clk(clk_buf2),
        .rst_n(rst_n_buf2),
        .current_events(current_events_buf1),
        .next_events(next_events)
    );
    
    // State register module
    EventRegister #(
        .BUF_SIZE(BUF_SIZE)
    ) event_register_inst (
        .clk(clk_buf3),
        .rst_n(rst_n_buf3),
        .next_events(next_events_buf1),
        .events_out(events)
    );
    
endmodule

//IEEE 1364-2005
module PtrCounter #(parameter PTR_WIDTH=3) (
    input wire clk,
    input wire rst_n,
    output reg [PTR_WIDTH-1:0] ptr_out
);
    // Local reset buffer to reduce fan-out
    wire rst_n_local;
    assign rst_n_local = rst_n;
    
    always @(posedge clk) begin
        if (!rst_n_local) begin
            ptr_out <= 0;
        end else begin
            ptr_out <= ptr_out + 1;
        end
    end
endmodule

//IEEE 1364-2005
module EventRotator #(parameter BUF_SIZE=8) (
    input wire clk,
    input wire rst_n,
    input wire [BUF_SIZE-1:0] current_events,
    output wire [BUF_SIZE-1:0] next_events
);
    // Split the logic into smaller chunks to reduce path delay
    wire [BUF_SIZE-1:0] shifted_events;
    wire msb_bit;
    
    assign msb_bit = current_events[BUF_SIZE-1];
    assign shifted_events = current_events << 1;
    assign next_events = shifted_events | msb_bit;
endmodule

//IEEE 1364-2005
module EventRegister #(parameter BUF_SIZE=8) (
    input wire clk,
    input wire rst_n,
    input wire [BUF_SIZE-1:0] next_events,
    output reg [BUF_SIZE-1:0] events_out
);
    // Local reset buffer to reduce fan-out
    wire rst_n_local;
    assign rst_n_local = rst_n;
    
    // Local next_events buffer
    reg [BUF_SIZE-1:0] next_events_local;
    
    always @(posedge clk) begin
        next_events_local <= next_events;
    end
    
    always @(posedge clk) begin
        if (!rst_n_local) begin
            events_out <= 1;
        end else begin
            events_out <= next_events_local;
        end
    end
endmodule