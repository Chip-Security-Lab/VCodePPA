//SystemVerilog
module decoder_priority #(WIDTH=4) (
    input [WIDTH-1:0] req,
    output [$clog2(WIDTH)-1:0] grant
);

    // Priority encoder submodule
    priority_encoder #(.WIDTH(WIDTH)) pe_inst (
        .req(req),
        .grant(grant)
    );

endmodule

module priority_encoder #(WIDTH=4) (
    input [WIDTH-1:0] req,
    output reg [$clog2(WIDTH)-1:0] grant
);

    integer i;
    always @* begin
        grant = 0;
        for(i=0; i<WIDTH; i=i+1)
            if(req[i]) grant = i;
    end

endmodule