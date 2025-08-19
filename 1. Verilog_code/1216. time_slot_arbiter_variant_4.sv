//SystemVerilog
module time_slot_arbiter #(
    parameter WIDTH = 4,
    parameter SLOT = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] req_i,
    output wire [WIDTH-1:0] grant_o
);
    // Internal signals
    wire [$clog2(SLOT)-1:0] counter;
    wire [WIDTH-1:0] rotation;
    wire [WIDTH-1:0] req_masked;
    wire counter_reload;
    
    // Counter management module
    counter_manager #(
        .SLOT(SLOT)
    ) u_counter_manager (
        .clk(clk),
        .rst_n(rst_n),
        .counter_reload(counter_reload),
        .counter(counter)
    );
    
    // Rotation vector management module
    rotation_manager #(
        .WIDTH(WIDTH)
    ) u_rotation_manager (
        .clk(clk),
        .rst_n(rst_n),
        .counter(counter),
        .rotation(rotation)
    );
    
    // Request masking and priority resolution
    request_handler #(
        .WIDTH(WIDTH)
    ) u_request_handler (
        .req_i(req_i),
        .rotation(rotation),
        .req_masked(req_masked)
    );
    
    // Grant generation module
    grant_generator #(
        .WIDTH(WIDTH)
    ) u_grant_generator (
        .clk(clk),
        .rst_n(rst_n),
        .counter(counter),
        .rotation(rotation),
        .req_masked(req_masked),
        .grant_o(grant_o)
    );
    
    // Counter reload condition
    assign counter_reload = (counter >= SLOT-1);
    
endmodule

// Counter management module
module counter_manager #(
    parameter SLOT = 8
)(
    input wire clk,
    input wire rst_n,
    input wire counter_reload,
    output reg [$clog2(SLOT)-1:0] counter
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter <= 0;
        end else begin
            counter <= counter_reload ? 0 : counter + 1;
        end
    end
endmodule

// Rotation vector management module
module rotation_manager #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [$clog2(8)-1:0] counter,
    output reg [WIDTH-1:0] rotation
);
    wire [WIDTH-1:0] next_rotation;
    
    // Calculate next rotation value
    assign next_rotation = {rotation[WIDTH-2:0], rotation[WIDTH-1]};
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rotation <= 1;
        end else if(counter == 0) begin
            rotation <= next_rotation;
        end
    end
endmodule

// Request handler module
module request_handler #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] req_i,
    input wire [WIDTH-1:0] rotation,
    output wire [WIDTH-1:0] req_masked
);
    // Apply priority mask to request
    assign req_masked = req_i & rotation;
endmodule

// Grant generation module
module grant_generator #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [$clog2(8)-1:0] counter,
    input wire [WIDTH-1:0] rotation,
    input wire [WIDTH-1:0] req_masked,
    output reg [WIDTH-1:0] grant_o
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= 0;
        end else if(counter == 0) begin
            grant_o <= |req_masked ? rotation : 0;
        end
    end
endmodule